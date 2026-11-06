class CategoryDetail {
  final bool match;
  final String notes;

  CategoryDetail({
    required this.match,
    required this.notes,
  });

  factory CategoryDetail.fromJson(dynamic json) {
    if (json == null) {
      return CategoryDetail(match: false, notes: '-');
    }
    if (json is! Map) {
      return CategoryDetail(
        match: false,
        notes: json.toString(),
      );
    }
    return CategoryDetail(
      match: json['match'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'notes': notes,
    };
  }
}

class InspectionResult {
  final int similarityScore;
  final String status; // PASS, REVIEW, REJECT
  final bool isMatch;
  final String summary;
  final String scoreJustification; // Alasan terperinci perolehan persentase skor
  final CategoryDetail textAccuracy;
  final CategoryDetail colorFidelity;
  final CategoryDetail alignment;
  final List<String> defects;
  final String recommendations;
  final String modelUsed;

  InspectionResult({
    required this.similarityScore,
    required this.status,
    required this.isMatch,
    required this.summary,
    required this.scoreJustification,
    required this.textAccuracy,
    required this.colorFidelity,
    required this.alignment,
    required this.defects,
    required this.recommendations,
    this.modelUsed = 'gemini-3.1-flash-lite',
  });

  factory InspectionResult.fromJson(
    Map<String, dynamic> json, {
    String modelUsed = 'gemini-3.1-flash-lite',
  }) {
    final rawDetails = json['analysis_details'];
    final Map<String, dynamic> details = (rawDetails is Map)
        ? rawDetails.map((k, v) => MapEntry(k.toString(), v))
        : {};

    // Parse defects list safely
    final rawDefects = details['defects_found'] ?? json['defects_found'];
    final List<String> parsedDefects;
    if (rawDefects is List) {
      parsedDefects = rawDefects
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawDefects != null && rawDefects.toString().trim().isNotEmpty) {
      parsedDefects = [rawDefects.toString().trim()];
    } else {
      parsedDefects = [];
    }

    final scoreVal = json['similarity_score'];
    final int score;
    if (scoreVal is num) {
      score = scoreVal.toInt();
    } else {
      final cleanScoreStr =
          scoreVal?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
      score = int.tryParse(cleanScoreStr) ?? 0;
    }

    final rawStatus = (json['status']?.toString() ?? 'REVIEW').toUpperCase();
    final status = (rawStatus == 'PASS' || rawStatus == 'REJECT' || rawStatus == 'REVIEW')
        ? rawStatus
        : (score >= 85 ? 'PASS' : (score >= 70 ? 'REVIEW' : 'REJECT'));

    final rawJustification = json['score_justification']?.toString() ??
        json['score_reason']?.toString() ??
        '';

    final scoreJustification = rawJustification.trim().isNotEmpty
        ? rawJustification.trim()
        : (score >= 85
            ? 'Skor tinggi ($score%) diperoleh karena cetakan aktual memiliki tingkat kesesuaian tinggi dengan sample proof, teks dan grafis presisi.'
            : (score >= 70
                ? 'Skor ($score%) berada dalam ambang review karena ditemukan deviasi minor pada cetakan yang mengurangi tingkat kemiripan.'
                : 'Skor rendah ($score%) disebabkan oleh ketidaksesuaian signifikan atau cacat fisik pada cetakan dibanding sample standar master proof.'));

    return InspectionResult(
      similarityScore: score.clamp(0, 100),
      status: status,
      isMatch: json['is_match'] == true || status == 'PASS',
      summary: json['summary']?.toString() ?? 'Hasil analisis kemiripan cetak.',
      scoreJustification: scoreJustification,
      textAccuracy: CategoryDetail.fromJson(details['text_accuracy']),
      colorFidelity: CategoryDetail.fromJson(details['color_fidelity']),
      alignment: CategoryDetail.fromJson(details['alignment']),
      defects: parsedDefects,
      recommendations: json['recommendations']?.toString() ??
          'Silakan periksa kembali hasil cetakan fisik.',
      modelUsed: modelUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'similarity_score': similarityScore,
      'status': status,
      'is_match': isMatch,
      'summary': summary,
      'score_justification': scoreJustification,
      'analysis_details': {
        'text_accuracy': textAccuracy.toJson(),
        'color_fidelity': colorFidelity.toJson(),
        'alignment': alignment.toJson(),
        'defects_found': defects,
      },
      'recommendations': recommendations,
      'model_used': modelUsed,
    };
  }
}
