// ignore_for_file: unnecessary_underscores

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/feed_item_widget.dart';
import '../widgets/feed_header.dart';
import '../../post_detail/screens/post_detail_screen.dart';
import '../../create_post/screens/create_post_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollDebounceTimer;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Debounce scroll events to prevent excessive API calls
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(AppConstants.scrollDebounce, () {
        if (!_isLoadingMore && mounted) {
          setState(() {
            _isLoadingMore = true;
          });
          ref.read(postsProvider.notifier).loadPosts().then((_) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          });
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).refreshPosts();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Selective watching for better performance
    final postsState = ref.watch(postsProvider);
    final isLoading = ref.watch(
      postsProvider.select((state) => state.isLoading),
    );
    final user = ref.watch(authProvider.select((state) => state.user));

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo, points, and profile
            FeedHeader(user: user),

            // Feed Content
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                enablePullDown: true,
                header: ClassicHeader(
                  refreshingText: 'Refreshing...',
                  completeText: 'Refreshed',
                  idleText: 'Pull to refresh',
                  releaseText: 'Release to refresh',
                  textStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                child: postsState.posts.isEmpty && isLoading
                    ? Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            );
                          },
                          child: const CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                          ),
                        ),
                      )
                    : postsState.posts.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        cacheExtent: 500,
                        itemCount:
                            postsState.posts.length +
                            (postsState.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index >= postsState.posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            );
                          }

                          final post = postsState.posts[index];
                          // Removed expensive TweenAnimationBuilder for better performance
                          return RepaintBoundary(
                            child: FeedItemWidget(
                              key: ValueKey(post.id),
                              post: post,
                              onLike: () {
                                ref
                                    .read(postsProvider.notifier)
                                    .toggleLike(post.id);
                              },
                              onComment: () {
                                  context.pushSmooth(
                                        PostDetailScreen(postId: post.id),
                                );
                              },
                              onShare: () {
                                // Handle share
                              },
                              onTap: () {
                                  context.pushSmooth(
                                        PostDetailScreen(postId: post.id),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
            ),
          );
        },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts yet',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
                fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start sharing your moments!',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
                fontFamily: '.SF Pro Display',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
                context.pushSmooth(const CreatePostScreen());
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create your first post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
