// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/comments_provider.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/api_provider.dart';
import '../widgets/comment_item_widget.dart';
import '../../feed/widgets/feed_item_widget.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  PostModel? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = PostModel.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    await ref
        .read(commentsProvider(widget.postId).notifier)
        .addComment(_commentController.text.trim());
    _commentController.clear();
    if (mounted) {
      await _loadPost();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.iconTheme.color),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/app_icon.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.iconTheme.color),
          title: Text(
            'Post',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontFamily: '.SF Pro Display',
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Post not found',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontFamily: '.SF Pro Display',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Post',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontFamily: '.SF Pro Display',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Post content
                  FeedItemWidget(
                    key: ValueKey(_post!.id),
                    post: _post!,
                    onLike: () {
                      ref.read(postsProvider.notifier).toggleLike(_post!.id);
                      _loadPost();
                    },
                  ),

                  // Comments section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          'Comments',
                          style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            color: theme.textTheme.titleMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Only watch comment count
                        Consumer(
                          builder: (context, ref, child) {
                            final commentCount = ref.watch(
                              commentsProvider(
                                widget.postId,
                              ).select((state) => state.comments.length),
                            );
                            if (commentCount > 0) {
                              return Text(
                                '$commentCount',
                                style: TextStyle(
                            fontFamily: '.SF Pro Display',
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 14,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Comment list
                  Consumer(
                    builder: (context, ref, child) {
                      final commentsState = ref.watch(
                        commentsProvider(widget.postId),
                      );
                      if (commentsState.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        );
                      }
                      if (commentsState.comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(
                            fontFamily: '.SF Pro Display',
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: commentsState.comments.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, index) {
                          final comment = commentsState.comments[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 250 + (index * 40),
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: child,
                                ),
                              );
                            },
                            child: CommentItemWidget(
                            key: ValueKey(comment.id),
                            comment: comment,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Space for input bar
                ],
              ),
            ),
          ),

          // Comment input
          Builder(
            builder: (context) {
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onPressed: _addComment,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
