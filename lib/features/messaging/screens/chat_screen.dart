import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/messages_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  SocketService? _socketService;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversation.id;
    // Store socket service reference before any async operations
    _socketService = ref.read(socketServiceProvider);

    // Load messages and join conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        ref
            .read(messagesProvider(widget.conversation.id).notifier)
            .loadMessages();
        _socketService?.joinConversation(widget.conversation.id);
        // Mark as read - use a delayed callback to avoid issues
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            try {
              ref
                  .read(messagesProvider(widget.conversation.id).notifier)
                  .markAsRead();
            } catch (e) {
              // Widget disposed, ignore
            }
          }
        });
      } catch (e) {
        // Widget disposed, ignore
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Leave conversation using stored reference (don't use ref after dispose)
    _socketService?.leaveConversation(
      _conversationId ?? widget.conversation.id,
    );
    super.dispose();
  }

  void _onMessageChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(messagesProvider(widget.conversation.id).notifier).startTyping();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        ref
            .read(messagesProvider(widget.conversation.id).notifier)
            .stopTyping();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    _messageController.clear();
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      ref.read(messagesProvider(widget.conversation.id).notifier).stopTyping();
    }

    await ref
        .read(messagesProvider(widget.conversation.id).notifier)
        .sendMessage(text, currentUser);

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messagesState = ref.watch(messagesProvider(widget.conversation.id));
    final currentUser = ref.watch(authProvider.select((state) => state.user));

    // Auto-scroll when new messages arrive
    if (messagesState.messages.isNotEmpty && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    final displayName =
        widget.conversation.displayName ?? widget.conversation.username;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              backgroundImage: widget.conversation.avatarUrl != null
                  ? NetworkImage(widget.conversation.avatarUrl!)
                  : null,
              child: widget.conversation.avatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
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
                  Text(
                    displayName,
                    style: TextStyle(
                      color: theme.textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (messagesState.isTyping &&
                      messagesState.typingUserId != currentUser?.id)
                    _TypingIndicator(theme: theme),
                ],
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesState.isLoading && messagesState.messages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  )
                : messagesState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: theme.iconTheme.color?.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount:
                        messagesState.messages.length +
                        (messagesState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= messagesState.messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = messagesState.messages[index];
                      final isMe = message.senderId == currentUser?.id;

                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 200 + (index * 20)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                isMe ? 20 * (1 - value) : -20 * (1 - value),
                                0,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: _MessageBubble(
                          message: message,
                          isMe: isMe,
                          theme: theme,
                        ),
                      );
                    },
                  ),
          ),

          // Message Input
          Container(
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
                      controller: _messageController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
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
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onMessageChanged,
                      onSubmitted: (_) => _sendMessage(),
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
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              backgroundImage: message.sender?['avatarUrl'] != null
                  ? NetworkImage(message.sender!['avatarUrl'] as String)
                  : null,
              child: message.sender?['avatarUrl'] == null
                  ? Text(
                      (message.sender?['username'] as String? ?? '?')[0]
                          .toUpperCase(),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      )
                    : null,
                color: isMe
                    ? null
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                        : (isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1)),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LiveTimestamp(
                        timestamp: message.createdAt,
                        theme: theme,
                        isMe: isMe,
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _MessageStatus(isRead: message.isRead, theme: theme),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated typing indicator with three bouncing dots
class _TypingIndicator extends StatefulWidget {
  final ThemeData theme;

  const _TypingIndicator({required this.theme});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.theme.textTheme.bodySmall?.color ??
        Colors.grey.withValues(alpha: 0.7);

    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final animationValue = (_controller.value + delay) % 1.0;
              final offset =
                  (animationValue < 0.5
                      ? animationValue * 2
                      : 1 - (animationValue - 0.5) * 2) *
                  8.0;

              return Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == 2 ? 0 : 4,
                ),
                child: Transform.translate(
                  offset: Offset(0, -offset),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Live updating timestamp widget that shows actual time and updates periodically
class _LiveTimestamp extends StatefulWidget {
  final DateTime timestamp;
  final ThemeData theme;
  final bool isMe;

  const _LiveTimestamp({
    required this.timestamp,
    required this.theme,
    required this.isMe,
  });

  @override
  State<_LiveTimestamp> createState() => _LiveTimestampState();
}

class _LiveTimestampState extends State<_LiveTimestamp> {
  Timer? _updateTimer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update every minute to keep timestamps current
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final difference = now.difference(widget.timestamp);

    if (difference.inDays == 0) {
      // Today - show date and time (e.g., "Jan 15, 3:45 PM")
      _timeString = DateFormat('MMM d, h:mm a').format(widget.timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday - show date and time (e.g., "Jan 14, 3:45 PM")
      _timeString = DateFormat('MMM d, h:mm a').format(widget.timestamp);
    } else if (difference.inDays < 365) {
      // This year - show date and time (e.g., "Jan 15, 3:45 PM")
      _timeString = DateFormat('MMM d, h:mm a').format(widget.timestamp);
    } else {
      // Older - show full date and time (e.g., "Jan 15, 2024, 3:45 PM")
      _timeString = DateFormat('MMM d, y, h:mm a').format(widget.timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeString,
      style: TextStyle(
        color: widget.isMe
            ? widget.theme.colorScheme.onPrimary.withValues(alpha: 0.7)
            : widget.theme.textTheme.bodySmall?.color,
        fontSize: 11,
      ),
    );
  }
}

/// Message status indicator (sent, delivered, seen)
/// Shows different states: single check (sent), double check gray (delivered), double check blue (read)
class _MessageStatus extends StatelessWidget {
  final bool isRead;
  final ThemeData theme;

  const _MessageStatus({required this.isRead, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Status hierarchy:
    // - Single check (gray) = sent
    // - Double check (gray) = delivered
    // - Double check (blue) = read/seen

    // For now, we only have isRead status from the API
    // In a full implementation, you'd have: sent, delivered, read states
    // Assuming if not read, it's delivered (not just sent)

    if (isRead) {
      // Read/Seen status - blue double check
      return Icon(
        Icons.done_all_rounded,
        size: 16,
        color: theme.colorScheme.primary,
      );
    } else {
      // Delivered status - gray double check
      // (In a real app, you might show single check for "sent" first)
      return Icon(
        Icons.done_all_rounded,
        size: 16,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
      );
    }
  }
}
