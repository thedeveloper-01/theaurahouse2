import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user_stats_model.dart';
import 'api_provider.dart';

class UserStatsState {
  final UserStatsModel? stats;
  final bool isLoading;
  final String? error;

  UserStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  UserStatsState copyWith({
    UserStatsModel? stats,
    bool? isLoading,
    String? error,
  }) {
    return UserStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserStatsNotifier extends StateNotifier<UserStatsState> {
  final ApiService _apiService;

  UserStatsNotifier(this._apiService) : super(UserStatsState());

  Future<void> fetchUserStats(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getUserStats(userId);
      if (response.statusCode == 200) {
        final stats = UserStatsModel.fromJson(response.data);
        state = state.copyWith(stats: stats, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch user statistics',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void refresh(String userId) {
    fetchUserStats(userId);
  }
}

final userStatsProvider =
    StateNotifierProvider.family<UserStatsNotifier, UserStatsState, String>(
  (ref, userId) {
    final apiService = ref.watch(apiServiceProvider);
    final notifier = UserStatsNotifier(apiService);
    notifier.fetchUserStats(userId);
    return notifier;
  },
);

