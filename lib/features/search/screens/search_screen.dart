// ignore_for_file: unnecessary_import, unnecessary_underscores

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/page_transitions.dart';
import '../../profile/screens/profile_screen.dart';
import '../../messaging/screens/chat_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const SearchScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      // Search for users - this should return a list from the backend
      final response = await apiService.searchUsers(query.trim());

      // The search endpoint always returns a list
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
            _error = users.isEmpty ? 'No users found' : null;
          });
        }
      } else {
        // Empty or invalid response
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
            _error = 'No users found';
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          // Provide more specific error message
          if (e.toString().contains('500')) {
            _error = 'Server error. Please try again later.';
          } else if (e.toString().contains('404')) {
            _error = 'Search endpoint not found.';
          } else if (e.toString().contains('Network')) {
            _error = 'Network error. Please check your connection.';
          } else {
            _error = 'No users found';
          }
        });
      }
    }
  }

  Future<void> _handleChatButton(BuildContext context, UserModel user) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to start a conversation'),
          ),
        );
      }
      return;
    }

    // Don't allow chatting with yourself
    if (currentUser.id == user.id) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot chat with yourself')),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Create or get conversation
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .createOrGetConversation(user.id);

      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      if (conversation != null) {
        // Navigate to chat screen
        await context.pushSmooth(ChatScreen(conversation: conversation));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start conversation. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      // Extract error message (remove "Exception: " prefix if present)
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Show error with retry option for server errors
      final isServerError = errorMessage.toLowerCase().contains('server error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: '.SF Pro Display',
                ),
              ),
              if (isServerError) ...[
                const SizedBox(height: 4),
                Text(
                  'The server is experiencing issues. Please try again in a moment.',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
          duration: Duration(seconds: isServerError ? 6 : 4),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: isServerError
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _handleChatButton(context, user);
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.iconTheme.color,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        title: Text(
          'Search',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Search username...',
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.iconTheme.color?.withValues(alpha: 0.6),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: theme.iconTheme.color?.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _error = null;
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
                  setState(() {});
                  _debounceTimer?.cancel();
                  if (value.trim().isEmpty) {
                    setState(() {
                      _searchResults = [];
                      _error = null;
                    });
                  } else {
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        _performSearch(value);
                      },
                    );
                  }
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _performSearch(value);
                  }
                },
              ),
            ),
          ),

          // Search Results
          Expanded(child: _buildSearchResults(context)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return Center(
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
              child: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onPrimary,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Users',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                color: theme.textTheme.titleLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a username to search',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) {
        final theme = Theme.of(context);
        return Divider(height: 1, color: theme.dividerColor);
      },
      itemBuilder: (context, index) {
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
          child: _UserSearchResultItem(
            key: ValueKey(user.id),
            user: user,
            onTap: () {
              // Navigate to user profile with userId
              context.pushSmooth(ProfileScreen(userId: user.id));
            },
            onChat: () => _handleChatButton(context, user),
          ),
        );
      },
    );
  }
}

class _UserSearchResultItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback? onChat;

  const _UserSearchResultItem({
    super.key,
    required this.user,
    required this.onTap,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.username[0].toUpperCase(),
                            style: TextStyle(
                              fontFamily: '.SF Pro Display',
                              color: theme.textTheme.titleLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.username,
                          style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            color: theme.textTheme.titleMedium?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 14,
                          ),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.bio!,
                            style: TextStyle(
                              fontFamily: '.SF Pro Display',
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.iconTheme.color?.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Chat button - separate from the main tap area
        if (onChat != null) ...[
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onChat,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
