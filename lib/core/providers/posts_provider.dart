import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'api_provider.dart';

class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final ApiService _apiService;
  final StorageService _storageService;

  PostsNotifier(this._apiService, this._storageService) : super(PostsState()) {
    loadPosts();
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    if (!refresh && !state.hasMore) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getPosts(page: page, limit: 20);
      final List<dynamic> postsData = response.data['posts'] ?? [];
      final newPosts = postsData
          .map((json) => PostModel.fromJson(json))
          .toList();

      final updatedPosts = refresh ? newPosts : [...state.posts, ...newPosts];

      // Cache posts
      await _storageService.cachePosts(updatedPosts);

      state = state.copyWith(
        posts: updatedPosts,
        isLoading: false,
        hasMore: newPosts.length >= 20,
        currentPage: page + 1,
      );
    } catch (e) {
      // Try to load from cache
      final cachedPosts = await _storageService.getCachedPosts();
      state = state.copyWith(
        posts: cachedPosts,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshPosts() async {
    await loadPosts(refresh: true);
  }

  Future<void> toggleLike(String postId) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    final newIsLiked = !(post.isLiked ?? false);
    final newLikeCount = newIsLiked ? post.likeCount + 1 : post.likeCount - 1;

    // Optimistic update
    final updatedPost = post.copyWith(
      isLiked: newIsLiked,
      likeCount: newLikeCount,
    );

    final updatedPosts = List<PostModel>.from(state.posts);
    updatedPosts[postIndex] = updatedPost;
    state = state.copyWith(posts: updatedPosts);

    // Sync with backend
    try {
      await _apiService.toggleLike(postId);
      await _storageService.cachePost(updatedPost);
    } catch (e) {
      // Revert on error
      final revertedPost = post.copyWith(
        isLiked: !newIsLiked,
        likeCount: post.likeCount,
      );
      updatedPosts[postIndex] = revertedPost;
      state = state.copyWith(posts: updatedPosts);
    }
  }

  Future<void> createPost({
    String? text,
    required List<String> filePaths,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiService.createPost(
        text: text,
        filePaths: filePaths,
      );

      // Add the newly created post to the state immediately
      if (response.data != null) {
        try {
          final newPost = PostModel.fromJson(response.data);
          final updatedPosts = [newPost, ...state.posts];
          state = state.copyWith(posts: updatedPosts, isLoading: false);
          // Cache the new post
          await _storageService.cachePost(newPost);
        } catch (e) {
          debugPrint('Error parsing new post: $e');
        }
      }

      // Also refresh to get the latest posts from server
      await refreshPosts();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error in createPost provider: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow; // Re-throw so UI can handle it
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _apiService.deletePost(postId);
      final updatedPosts = state.posts.where((p) => p.id != postId).toList();
      state = state.copyWith(posts: updatedPosts);
      await _storageService.deleteCachedPost(postId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return PostsNotifier(apiService, storageService);
});
