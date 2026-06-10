/// Input validators for user content
class Validators {
  // Text validation
  static const int maxPostTextLength = 5000;
  static const int maxCommentTextLength = 1000;
  static const int maxBioLength = 500;
  static const int maxDisplayNameLength = 50;

  // File validation
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxImagesPerPost = 10;

  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  static const List<String> allowedVideoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
  ];

  /// Validate post text
  static String? validatePostText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null; // Optional field
    }

    if (text.length > maxPostTextLength) {
      return 'Post text cannot exceed $maxPostTextLength characters';
    }

    return null;
  }

  /// Validate comment text
  static String? validateCommentText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Comment cannot be empty';
    }

    if (text.length > maxCommentTextLength) {
      return 'Comment cannot exceed $maxCommentTextLength characters';
    }

    return null;
  }

  /// Validate bio
  static String? validateBio(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return null; // Optional field
    }

    if (bio.length > maxBioLength) {
      return 'Bio cannot exceed $maxBioLength characters';
    }

    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null; // Optional field
    }

    if (name.length > maxDisplayNameLength) {
      return 'Display name cannot exceed $maxDisplayNameLength characters';
    }

    return null;
  }

  /// Validate file size
  static String? validateFileSize(int sizeInBytes, bool isVideo) {
    final sizeMB = sizeInBytes / (1024 * 1024);
    final maxSize = isVideo ? maxVideoSizeMB : maxImageSizeMB;

    if (sizeMB > maxSize) {
      return '${isVideo ? 'Video' : 'Image'} size cannot exceed ${maxSize}MB';
    }

    return null;
  }

  /// Validate file extension
  static String? validateFileExtension(String filename, bool isVideo) {
    final extension = filename.split('.').last.toLowerCase();
    final allowedExtensions =
        isVideo ? allowedVideoExtensions : allowedImageExtensions;

    if (!allowedExtensions.contains(extension)) {
      return 'Invalid file type. Allowed: ${allowedExtensions.join(', ')}';
    }

    return null;
  }

  /// Sanitize text (remove potentially harmful content)
  static String sanitizeText(String text) {
    // Remove leading/trailing whitespace
    String sanitized = text.trim();

    // Remove excessive newlines (max 2 consecutive)
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove excessive spaces
    sanitized = sanitized.replaceAll(RegExp(r' {2,}'), ' ');

    return sanitized;
  }
}
