import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class CommentsState {
  final List<CommentModel> comments;
  final bool isLoading;
  final String? error;

  CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentsState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  final ApiService _apiService;
  final String postId;

  CommentsNotifier(this._apiService, this.postId) : super(CommentsState()) {
    loadComments();
  }

  Future<void> loadComments() async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await _apiService.getComments(postId);
      final List<dynamic> commentsData = response.data['comments'] ?? [];
      final comments = commentsData
          .map((json) => CommentModel.fromJson(json))
          .toList();
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addComment(String text, {String? parentCommentId}) async {
    try {
      await _apiService.createComment(postId, text, parentCommentId: parentCommentId);
      await loadComments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteComment(String id) async {
    try {
      await _apiService.deleteComment(id);
      await loadComments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
  (ref, postId) {
    final apiService = ref.watch(apiServiceProvider);
    return CommentsNotifier(apiService, postId);
  },
);

