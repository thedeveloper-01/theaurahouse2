import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/comment_model.dart';

class CommentItemWidget extends StatelessWidget {
  final CommentModel comment;

  const CommentItemWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            backgroundImage: comment.user?.avatarUrl != null
                ? CachedNetworkImageProvider(comment.user!.avatarUrl!)
                : null,
            child: comment.user?.avatarUrl == null
                ? Text(
                    comment.user?.username[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontFamily: '.SF Pro Display',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
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
                          text: '${comment.user?.username ?? "User"} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                        TextSpan(
                          text: comment.text,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontFamily: '.SF Pro Display',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        // Handle reply
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
