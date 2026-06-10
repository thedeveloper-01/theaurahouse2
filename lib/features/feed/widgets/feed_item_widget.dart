import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/models/post_model.dart';

class FeedItemWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const FeedItemWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTap,
  });

  @override
  State<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<FeedItemWidget>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentImageIndex = 0;
  bool _isVideoInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.post.isVideo && widget.post.mediaJson?.isNotEmpty == true) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    final videoUrl = widget.post.mediaJson?.first.url;
    if (videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoController
          ?.initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _chewieController = ChewieController(
                videoPlayerController: _videoController!,
                autoPlay: false,
                looping: false,
                aspectRatio: _videoController!.value.aspectRatio,
                showControls: true,
              );
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = false;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final user = post.user;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Username and Avatar at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  backgroundImage: user?.avatarUrl != null
                      ? CachedNetworkImageProvider(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null && user != null
                      ? Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontFamily: '.SF Pro Display',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Username
                Expanded(
                  child: Text(
                    user?.username ?? 'User',
                    style: TextStyle(
                      color: theme.textTheme.titleMedium?.color,
                      fontFamily: '.SF Pro Display',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // More options
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.iconTheme.color,
                    size: 20,
                  ),
                  onPressed: () {
                    // Handle more options
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Media Content (full width, no border radius for Instagram style)
          GestureDetector(onTap: widget.onTap, child: _buildMedia()),

          // Interaction Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _buildInteractionButton(
                  icon: post.isLiked == true
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.isLiked == true ? Colors.red : null,
                  onTap: widget.onLike,
                ),
                const SizedBox(width: 16),
                _buildInteractionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: widget.onComment ?? widget.onTap,
                ),
                const SizedBox(width: 16),
                _buildInteractionButton(
                  icon: Icons.send_outlined,
                  onTap: widget.onShare,
                ),
                const Spacer(),
                _buildInteractionButton(
                  icon: Icons.bookmark_border_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Like count
          if (post.likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                '${_formatCount(post.likeCount)} likes',
                          style: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontFamily: '.SF Pro Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

          // Caption with Username
          if (post.text != null && post.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                    fontFamily: '.SF Pro Display',
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '${user?.username ?? "User"} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: '.SF Pro Display',
                      ),
                          ),
                          TextSpan(
                            text: post.text,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

          // View comments
          if (post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: widget.onComment ?? widget.onTap,
                child: Text(
                  'View all ${_formatCount(post.commentCount)} comments',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _formatTimestamp(post.createdAt),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.post.isVideo) {
      return _buildVideo();
    } else {
      return _buildImageCarousel();
    }
  }

  Widget _buildVideo() {
    if (_isVideoInitialized && _chewieController != null) {
      return SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio like Instagram
        child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      final theme = Theme.of(context);
      return SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio like Instagram
        child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildImageCarousel() {
    final images = widget.post.mediaJson!
        .where((m) => m.type == 'image')
        .map((m) => m.url)
        .toList();

    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1.0, // Square aspect ratio like Instagram
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                  placeholder: (context, url) {
                    final theme = Theme.of(context);
                    return Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                  ),
                    );
                  },
                  errorWidget: (context, url, error) {
                    final theme = Theme.of(context);
                    return Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Icon(
                    Icons.error_outline,
                        color: theme.iconTheme.color?.withValues(alpha: 0.5),
                    size: 48,
                  ),
                    );
                  },
              );
            },
          ),
          if (images.length > 1)
            Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return _AnimatedInteractionButton(
      onTap: onTap,
      child: Icon(icon, color: color ?? theme.iconTheme.color, size: 28),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _AnimatedInteractionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedInteractionButton({required this.child, this.onTap});

  @override
  State<_AnimatedInteractionButton> createState() =>
      _AnimatedInteractionButtonState();
}

class _AnimatedInteractionButtonState extends State<_AnimatedInteractionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
