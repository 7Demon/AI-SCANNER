import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ProcessedImage {
  final Uint8List bytes;
  final String base64Data;
  final int originalWidth;
  final int originalHeight;
  final int compressedWidth;
  final int compressedHeight;
  final int byteSize;

  ProcessedImage({
    required this.bytes,
    required this.base64Data,
    required this.originalWidth,
    required this.originalHeight,
    required this.compressedWidth,
    required this.compressedHeight,
    required this.byteSize,
  });

  String get formattedSize {
    if (byteSize < 1024) return '$byteSize B';
    if (byteSize < 1024 * 1024) {
      return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Mengambil gambar dari Kamera atau Galeri, lalu mengompresi secara lokal.
  static Future<ProcessedImage?> pickAndCompressImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final Uint8List rawBytes = await pickedFile.readAsBytes();

      // Decode gambar menggunakan pustaka murni Dart 'image'
      final img.Image? decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        // Fallback jika decode gagal: gunakan bytes mentah
        final base64String = base64Encode(rawBytes);
        return ProcessedImage(
          bytes: rawBytes,
          base64Data: base64String,
          originalWidth: 0,
          originalHeight: 0,
          compressedWidth: 0,
          compressedHeight: 0,
          byteSize: rawBytes.length,
        );
      }

      final int originalW = decoded.width;
      final int originalH = decoded.height;

      // Resize jika dimensi lebih dari 1280px (hemat bandwidth & latensi)
      img.Image resized = decoded;
      const int maxDimension = 1280;
      if (originalW > maxDimension || originalH > maxDimension) {
        if (originalW >= originalH) {
          resized = img.copyResize(decoded, width: maxDimension);
        } else {
          resized = img.copyResize(decoded, height: maxDimension);
        }
      }

      // Encode kembali ke JPEG kualitas 80%
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 80),
      );

      final String base64Data = base64Encode(compressedBytes);

      return ProcessedImage(
        bytes: compressedBytes,
        base64Data: base64Data,
        originalWidth: originalW,
        originalHeight: originalH,
        compressedWidth: resized.width,
        compressedHeight: resized.height,
        byteSize: compressedBytes.length,
      );
    } catch (e) {
      return null;
    }
  }
}

