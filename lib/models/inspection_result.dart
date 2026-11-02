class CategoryDetail {
  final bool match;
  final String notes;

  CategoryDetail({
    required this.match,
    required this.notes,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CategoryDetail(match: false, notes: '-');
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
  final CategoryDetail textAccuracy;
  final CategoryDetail colorFidelity;
  final CategoryDetail alignment;
  final List<String> defects;
  final String recommendations;

  InspectionResult({
    required this.similarityScore,
    required this.status,
    required this.isMatch,
    required this.summary,
    required this.textAccuracy,
    required this.colorFidelity,
    required this.alignment,
    required this.defects,
    required this.recommendations,
  });

  factory InspectionResult.fromJson(Map<String, dynamic> json) {
    final details = json['analysis_details'] as Map<String, dynamic>? ?? {};

    // Parse defects list safely
    final rawDefects = details['defects_found'] as List<dynamic>? ??
        json['defects_found'] as List<dynamic>? ??
        [];
    final parsedDefects = rawDefects
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final score = (json['similarity_score'] is num)
        ? (json['similarity_score'] as num).toInt()
        : int.tryParse(json['similarity_score']?.toString() ?? '0') ?? 0;

    final rawStatus = (json['status']?.toString() ?? 'REVIEW').toUpperCase();
    final status = (rawStatus == 'PASS' || rawStatus == 'REJECT' || rawStatus == 'REVIEW')
        ? rawStatus
        : (score >= 85 ? 'PASS' : (score >= 70 ? 'REVIEW' : 'REJECT'));

    return InspectionResult(
      similarityScore: score.clamp(0, 100),
      status: status,
      isMatch: json['is_match'] == true || status == 'PASS',
      summary: json['summary']?.toString() ?? 'Hasil analisis kemiripan cetak.',
      textAccuracy: CategoryDetail.fromJson(
        details['text_accuracy'] as Map<String, dynamic>?,
      ),
      colorFidelity: CategoryDetail.fromJson(
        details['color_fidelity'] as Map<String, dynamic>?,
      ),
      alignment: CategoryDetail.fromJson(
        details['alignment'] as Map<String, dynamic>?,
      ),
      defects: parsedDefects,
      recommendations: json['recommendations']?.toString() ??
          'Silakan periksa kembali hasil cetakan fisik.',
    );
  }
}

