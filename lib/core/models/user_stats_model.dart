class UserStatsModel {
  final int postCount;
  final int followersCount;
  final int followingCount;
  final int imagesCount;
  final int reelsCount;
  final int eventsCount;

  UserStatsModel({
    required this.postCount,
    required this.followersCount,
    required this.followingCount,
    required this.imagesCount,
    required this.reelsCount,
    required this.eventsCount,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      postCount: json['postCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      imagesCount: json['imagesCount'] as int? ?? 0,
      reelsCount: json['reelsCount'] as int? ?? 0,
      eventsCount: json['eventsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postCount': postCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'imagesCount': imagesCount,
      'reelsCount': reelsCount,
      'eventsCount': eventsCount,
    };
  }
}

