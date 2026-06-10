import 'user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String? userId;
  final UserModel? user;
  final String? parentCommentId;
  final String text;
  final DateTime createdAt;
  final List<CommentModel>? replies;

  CommentModel({
    required this.id,
    required this.postId,
    this.userId,
    this.user,
    this.parentCommentId,
    required this.text,
    required this.createdAt,
    this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null || json['text'] == null) {
        throw Exception('Missing required fields in CommentModel');
      }

      return CommentModel(
        id: json['id'] as String,
        postId: (json['postId'] ?? json['post_id']) as String? ?? '',
        userId: json['userId'] ?? json['user_id'],
        user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
        parentCommentId: json['parentCommentId'] ?? json['parent_comment_id'],
        text: json['text'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
        replies: json['replies'] != null
            ? (json['replies'] as List)
                  .map((item) => CommentModel.fromJson(item))
                  .toList()
            : null,
      );
    } catch (e) {
      throw Exception('Failed to parse CommentModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'user': user?.toJson(),
      'parentCommentId': parentCommentId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      if (replies != null) 'replies': replies!.map((r) => r.toJson()).toList(),
    };
  }
}
