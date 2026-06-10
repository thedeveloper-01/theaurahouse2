class MediaItemModel {
  final String url;
  final String type; // 'image' or 'video'
  final int? width;
  final int? height;
  final int? duration; // for videos in seconds
  final String? key; // Storage key for deletion

  MediaItemModel({
    required this.url,
    required this.type,
    this.width,
    this.height,
    this.duration,
    this.key,
  });

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      url: json['url'],
      type: json['type'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
      key: json['key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (key != null) 'key': key,
    };
  }
}

