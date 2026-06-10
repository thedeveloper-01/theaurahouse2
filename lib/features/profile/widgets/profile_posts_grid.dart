import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';

class ProfilePostsGrid extends ConsumerWidget {
  final String? filterType; // 'image', 'reel', 'event'
  final bool showTextOverlay;
  final String? userId; // Optional userId to show posts for a specific user

  const ProfilePostsGrid({
    super.key,
    this.filterType,
    this.showTextOverlay = false,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use provided userId or fall back to current user
    final currentUserId =
        userId ?? ref.watch(authProvider.select((state) => state.user?.id));
    final postsState = ref.watch(postsProvider);

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    // Filter posts by type and user
    var userPosts = postsState.posts
        .where((p) => p.userId == currentUserId)
        .toList();

    // Sort by creation date (newest first)
    userPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filterType == 'reel') {
      userPosts = userPosts.where((p) => p.isVideo).toList();
    } else if (filterType == 'image') {
      userPosts = userPosts.where((p) => !p.isVideo).toList();
    }

    if (userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_off_rounded,
              size: 48,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${filterType ?? 'posts'} yet',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontFamily: '.SF Pro Display',
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: userPosts.length,
      cacheExtent: 500, // Optimize scrolling
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 30)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
            );
          },
          child: RepaintBoundary(
          child: _PostGridItem(
            key: ValueKey(post.id),
            post: post,
            showTextOverlay: showTextOverlay,
            ),
          ),
        );
      },
    );
  }
}

class _PostGridItem extends StatelessWidget {
  final dynamic post;
  final bool showTextOverlay;

  const _PostGridItem({
    super.key,
    required this.post,
    required this.showTextOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstMedia = post.mediaJson?.isNotEmpty == true
        ? post.mediaJson!.first
        : null;

    return GestureDetector(
      onTap: () {
        // Navigate to post detail
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image/Video thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: firstMedia != null
                ? CachedNetworkImage(
                    imageUrl: firstMedia.url,
                    fit: BoxFit.cover,
                    memCacheWidth: 300, // Optimize memory
                    memCacheHeight: 300,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surface,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.iconTheme.color?.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surface,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: theme.iconTheme.color?.withValues(alpha: 0.3),
                      ),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surface,
                    child: Icon(
                      Icons.image_rounded,
                      color: theme.iconTheme.color?.withValues(alpha: 0.3),
                    ),
                  ),
          ),
          // Video indicator
          if (post.isVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                    child: Icon(
                  Icons.play_circle_filled_rounded,
                      color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
                  );
                },
              ),
            ),
          // Text overlay at bottom
          if (showTextOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  post.text != null && post.text!.isNotEmpty
                      ? (post.text!.length > 30
                            ? '${post.text!.substring(0, 30)}...'
                            : post.text!)
                      : 'Post',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontFamily: '.SF Pro Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
