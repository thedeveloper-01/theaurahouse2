class UserModel {
  final String id;
  final String username;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    this.displayName,
    this.email,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null || json['username'] == null) {
        throw Exception('Missing required fields: id or username');
      }

      return UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] ?? json['display_name'],
        email: json['email'],
        bio: json['bio'],
        avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : (json['updated_at'] != null
                ? DateTime.parse(json['updated_at'])
                : DateTime.now()),
      );
    } catch (e) {
      throw Exception('Failed to parse UserModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
