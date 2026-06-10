import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/page_transitions.dart';
import 'chat_screen.dart';

class MessagingCenterScreen extends ConsumerStatefulWidget {
  const MessagingCenterScreen({super.key});

  @override
  ConsumerState<MessagingCenterScreen> createState() =>
      _MessagingCenterScreenState();
}

class _MessagingCenterScreenState extends ConsumerState<MessagingCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  List<ConversationModel> _filterConversations(
    List<ConversationModel> conversations,
    String query,
  ) {
    if (query.isEmpty) return conversations;
    final lowerQuery = query.toLowerCase();
    return conversations.where((conv) {
      final name = (conv.displayName ?? conv.username).toLowerCase();
      final lastMsg = (conv.lastMessage ?? '').toLowerCase();
      return name.contains(lowerQuery) || lastMsg.contains(lowerQuery);
    }).toList();
  }

  Future<void> _performUserSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.searchUsers(query.trim());

      if (response.data != null && response.data is List) {
        final List<dynamic> dataList = response.data as List;
        final users = dataList
            .map((json) {
              try {
                return UserModel.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing user: $e');
                return null;
              }
            })
            .whereType<UserModel>()
            .toList();

        if (mounted) {
          setState(() {
            _searchResults = users;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _createConversationWithUser(UserModel user) async {
    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .createOrGetConversation(user.id);

      // Refresh conversations
      await ref.read(conversationsProvider.notifier).refreshConversations();

      // Clear search
      _searchController.clear();
      setState(() {
        _searchQuery = '';
        _searchResults = [];
      });

      if (mounted && conversation != null) {
        await context.pushSmooth(ChatScreen(conversation: conversation));
      }
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to start conversation'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conversationsState = ref.watch(conversationsProvider);
    final allConversations = conversationsState.conversations;
    final conversations = _filterConversations(allConversations, _searchQuery);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Beautiful gradient header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                            const Color(0xFF0F3460),
                          ]
                        : [
                            const Color(0xFFE8F4F8),
                            const Color(0xFFD6E9F0),
                            const Color(0xFFC4DEE8),
                          ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 24,
              ),
            ),
                            const SizedBox(width: 12),
            Text(
              'Messages',
              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 32,
                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                fontFamily: '.SF Pro Display',
              ),
            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
            icon: Icon(
              Icons.add_comment_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              // TODO: Navigate to new conversation screen
            },
            tooltip: 'New message',
                              ),
                            ),
                          ],
          ),
        ],
      ),
                  ),
                ),
              ),
            ),
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                ),
                  ],
              ),
              child: TextField(
                controller: _searchController,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontFamily: '.SF Pro Display',
                  ),
                decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 15,
                      fontFamily: '.SF Pro Display',
                    ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.iconTheme.color?.withValues(alpha: 0.6),
                      size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: theme.iconTheme.color?.withValues(
                              alpha: 0.6,
                            ),
                              size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });

                  _searchDebounceTimer?.cancel();
                  if (value.trim().isNotEmpty) {
                    _searchDebounceTimer = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        _performUserSearch(value);
                      },
                    );
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
              ),
            ),
          ),
          ),
          // Content
          _searchQuery.isNotEmpty && _searchResults.isNotEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = _searchResults[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 250 + (index * 40)),
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
                      child: _UserSearchItem(
                        key: ValueKey(user.id),
                        user: user,
                        onTap: () => _createConversationWithUser(user),
                      ),
                      );
                  }, childCount: _searchResults.length),
                  )
                : _isSearching
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  )
                : conversationsState.isLoading && allConversations.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  )
                : conversationsState.error != null && allConversations.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                          Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          conversationsState.error ?? 'Unknown error',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 14,
                            fontFamily: '.SF Pro Display',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(conversationsProvider.notifier)
                                .refreshConversations();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
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
                  )
                : conversations.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No users found'
                              : 'No messages yet',
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching with a different name'
                              : 'Start a conversation to see your messages here',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 16,
                            fontFamily: '.SF Pro Display',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                      ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                        final conversation = conversations[index];
                        final hasUnread = conversation.unreadCount > 0;

                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 250 + (index * 40)),
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
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ConversationItem(
                            key: ValueKey(conversation.id),
                            conversation: conversation,
                            hasUnread: hasUnread,
                          ),
                          ),
                        );
                    }, childCount: conversations.length),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final ConversationModel conversation;
  final bool hasUnread;

  const _ConversationItem({
    super.key,
    required this.conversation,
    required this.hasUnread,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else if (difference.inDays < 365) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = conversation.displayName ?? conversation.username;
    final lastMessageTime =
        conversation.lastMessageTime ?? conversation.updatedAt;

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
          context.pushSmooth(ChatScreen(conversation: conversation));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: hasUnread
                ? LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.05),
                          ]
                        : [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.05),
                          ],
                  )
                : null,
            color: hasUnread
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with gradient border
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnread
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            )
                          : null,
                      boxShadow: hasUnread
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    padding: hasUnread ? const EdgeInsets.all(2.5) : null,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    backgroundImage: conversation.avatarUrl != null
                        ? CachedNetworkImageProvider(conversation.avatarUrl!)
                        : null,
                    child: conversation.avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                              style: TextStyle(
                                fontSize: 22,
                              fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontFamily: '.SF Pro Display',
                            ),
                          )
                        : null,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                          ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 17,
                              color: theme.textTheme.titleLarge?.color,
                              letterSpacing: -0.3,
                              fontFamily: '.SF Pro Display',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                      conversation.lastMessage ?? 'No messages yet',
                      style: TextStyle(
                        fontSize: 14,
                              color: hasUnread
                                  ? theme.textTheme.bodyLarge?.color
                                  : theme.textTheme.bodySmall?.color,
                        fontWeight: hasUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                              height: 1.3,
                              fontFamily: '.SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              ),
                    borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                                fontFamily: '.SF Pro Display',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSearchItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserSearchItem({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = user.displayName ?? user.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Row(
            children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                            style: TextStyle(
                              fontSize: 22,
                          fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontFamily: '.SF Pro Display',
                        ),
                      )
                    : null,
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                        style: TextStyle(
                        fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: theme.textTheme.titleLarge?.color,
                          letterSpacing: -0.3,
                          fontFamily: '.SF Pro Display',
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                            height: 1.3,
                            fontFamily: '.SF Pro Display',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
