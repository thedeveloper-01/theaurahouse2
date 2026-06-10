import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _postsBoxName = 'posts';
  static const String _userBoxName = 'user';

  Future<void> init() async {
    // Hive.initFlutter() is called in main.dart
    // We use JSON storage (no adapters needed)
  }

  // Posts cache - using JSON storage
  Future<void> cachePosts(List<PostModel> posts) async {
    final box = await Hive.openBox(_postsBoxName);
    for (var post in posts) {
      await box.put(post.id, post.toJson());
    }
  }

  Future<List<PostModel>> getCachedPosts() async {
    try {
      final box = await Hive.openBox(_postsBoxName);
      final List<PostModel> posts = [];
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          posts.add(PostModel.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<void> cachePost(PostModel post) async {
    final box = await Hive.openBox(_postsBoxName);
    await box.put(post.id, post.toJson());
  }

  Future<PostModel?> getCachedPost(String id) async {
    try {
      final box = await Hive.openBox(_postsBoxName);
      final data = box.get(id);
      if (data != null) {
        return PostModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCachedPost(String id) async {
    final box = await Hive.openBox(_postsBoxName);
    await box.delete(id);
  }

  // User cache
  Future<void> cacheUser(UserModel user) async {
    final box = await Hive.openBox(_userBoxName);
    await box.put('current_user', user.toJson());
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      final data = box.get('current_user');
      if (data != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final postsBox = await Hive.openBox(_postsBoxName);
    final userBox = await Hive.openBox(_userBoxName);
    await postsBox.clear();
    await userBox.clear();
  }
}
