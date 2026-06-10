import 'user_model.dart';
import 'media_item_model.dart';

class PostModel {
  final String id;
  final String userId;
  final UserModel? user;
  final String? text;
  final List<MediaItemModel>? mediaJson;
  final bool isVideo;
  final String privacy;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool? isLiked; // Local state

  PostModel({
    required this.id,
    required this.userId,
    this.user,
    this.text,
    this.mediaJson,
    required this.isVideo,
    required this.privacy,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLiked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null || json['userId'] == null && json['user_id'] == null) {
        throw Exception('Missing required fields in PostModel');
      }

      return PostModel(
        id: json['id'] as String,
        userId: (json['userId'] ?? json['user_id']) as String,
        user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
        text: json['text'],
        mediaJson: json['mediaJson'] != null
            ? (json['mediaJson'] as List)
                .map((item) => MediaItemModel.fromJson(item))
                .toList()
            : null,
        isVideo: json['isVideo'] ?? json['is_video'] ?? false,
        privacy: json['privacy'] ?? 'public',
        likeCount: json['likeCount'] ?? json['like_count'] ?? 0,
        commentCount: json['commentCount'] ?? json['comment_count'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
        isLiked: json['isLiked'],
      );
    } catch (e) {
      throw Exception('Failed to parse PostModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user?.toJson(),
      'text': text,
      'mediaJson': mediaJson?.map((item) => item.toJson()).toList(),
      'isVideo': isVideo,
      'privacy': privacy,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    String? text,
    List<MediaItemModel>? mediaJson,
    bool? isVideo,
    String? privacy,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      text: text ?? this.text,
      mediaJson: mediaJson ?? this.mediaJson,
      isVideo: isVideo ?? this.isVideo,
      privacy: privacy ?? this.privacy,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

