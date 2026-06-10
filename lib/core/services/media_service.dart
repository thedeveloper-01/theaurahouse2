// ignore_for_file: unnecessary_import

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  // Pick image
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return null;
    return File(image.path);
  }

  // Pick video
  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final XFile? video = await _picker.pickVideo(source: source);
    if (video == null) return null;
    return File(video.path);
  }

  // Pick multiple images
  Future<List<File>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.map((xFile) => File(xFile.path)).toList();
  }

  // Compress image
  Future<File?> compressImage(
    File imageFile, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // Calculate new dimensions
      int width = originalImage.width;
      int height = originalImage.height;

      if (width > maxWidth) {
        height = (height * maxWidth / width).round();
        width = maxWidth;
      }

      // Resize and compress
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: width,
        height: height,
      );

      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      // Save to temp directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File('${tempDir.path}/$fileName');
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  // Generate video thumbnail
  Future<File?> generateVideoThumbnail(File videoFile) async {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 640,
        quality: 75,
      );

      if (thumbnailPath == null) return null;
      return File(thumbnailPath);
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  // Get file size in MB
  Future<double> getFileSizeMB(File file) async {
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}
