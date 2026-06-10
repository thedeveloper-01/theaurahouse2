import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_stats_provider.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/page_transitions.dart';
import '../../messaging/screens/chat_screen.dart';
import '../widgets/profile_posts_grid.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _profileUser;
  bool _isLoadingUser = false;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.userId != null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (widget.userId == null) return;

    setState(() {
      _isLoadingUser = true;
      _userError = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getUser(widget.userId!);

      if (mounted && response.data != null) {
        setState(() {
          _profileUser = UserModel.fromJson(response.data);
          _isLoadingUser = false;
        });

        // Load user stats and posts
        if (mounted) {
          ref
              .read(userStatsProvider(_profileUser!.id).notifier)
              .refresh(_profileUser!.id);
          ref.read(postsProvider.notifier).refreshPosts();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _userError = 'Failed to load user profile';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = widget.userId == null
          ? ref.read(authProvider).user
          : _profileUser;
      if (user != null && mounted) {
        ref.read(userStatsProvider(user.id).notifier).refresh(user.id);
        ref.read(postsProvider.notifier).refreshPosts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider.select((state) => state.user));
    final user = widget.userId != null ? _profileUser : currentUser;

    if (widget.userId != null && _isLoadingUser) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (widget.userId != null && _userError != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.iconTheme.color?.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _userError!,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontFamily: '.SF Pro Display',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontFamily: '.SF Pro Display',
            ),
          ),
        ),
      );
    }

    final statsState = ref.watch(userStatsProvider(user.id));
    final stats = statsState.stats;

    final postCount = stats?.postCount ?? 0;
    final followersCount = stats?.followersCount ?? 0;
    final followingCount = stats?.followingCount ?? 0;
    final imagesCount = stats?.imagesCount ?? 0;
    final reelsCount = stats?.reelsCount ?? 0;
    final eventsCount = stats?.eventsCount ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(context, user, currentUser),
            _buildProfileHeader(
            context,
            user,
              currentUser,
            statsState,
            postCount,
            followersCount,
            followingCount,
          ),
          ];
        },
        body: Column(
          children: [
          _buildTabsSection(
            context,
            statsState,
            imagesCount,
            reelsCount,
            eventsCount,
          ),
          Expanded(child: _buildContentGrid(context)),
        ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    UserModel user,
    UserModel? currentUser,
  ) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: theme.iconTheme.color),
          onPressed: () {
            // Handle more options
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserModel user,
    UserModel? currentUser,
    UserStatsState statsState,
    int postCount,
    int followersCount,
    int followingCount,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOwnProfile = currentUser?.id == user.id;

    return SliverToBoxAdapter(
      child: Container(
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
            padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
                // Profile Picture with gradient border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF6366F1),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                      ),
                  padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.scaffoldBackgroundColor,
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.username[0].toUpperCase(),
                              style: TextStyle(
                              fontSize: 40,
                                fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontFamily: '.SF Pro Display',
                              ),
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 24),
                // Name and Username
                        Text(
                          user.displayName ?? user.username,
                          style: TextStyle(
                    fontSize: 28,
                            fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                    letterSpacing: -0.5,
                    fontFamily: '.SF Pro Display',
                          ),
                        ),
                const SizedBox(height: 6),
                        Text(
                          '@${user.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                        fontFamily: '.SF Pro Display',
                      ),
                          ),
                        ),
                ],
                const SizedBox(height: 24),
                // Action Buttons
                Builder(
                  builder: (context) {
                    return Row(
                          children: [
                        if (isOwnProfile)
                          Expanded(
                            child: _buildGradientButton(
                              'Edit Profile',
                              const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              ),
                              () {
                                // Handle edit profile
                              },
                              theme,
                            ),
                          )
                        else ...[
                            Expanded(
                            child: _buildGradientButton(
                              'Follow',
                              LinearGradient(
                                colors: [
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFF6366F1),
                                ],
                              ),
                              () {
                                // Handle follow
                              },
                              theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                            child: _buildGradientButton(
                              'Message',
                              const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                              ),
                              () => _handleChatButton(context, user),
                              theme,
                              icon: Icons.chat_bubble_outline_rounded,
                              ),
                            ),
                          ],
                      ],
                    );
                  },
                    ),
                const SizedBox(height: 32),
              // Statistics
              statsState.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                          _buildStatCard(
                            _formatCount(postCount),
                            'Posts',
                            Icons.grid_view_rounded,
                            theme,
                          ),
                          _buildStatCard(
                          _formatCount(followersCount),
                            'Followers',
                            Icons.people_rounded,
                            theme,
                        ),
                          _buildStatCard(
                          _formatCount(followingCount),
                          'Following',
                            Icons.person_add_rounded,
                            theme,
                        ),
                      ],
                    ),
                const SizedBox(height: 24),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
    String text,
    Gradient gradient,
    VoidCallback onTap,
    ThemeData theme, {
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              if (icon != null) ...[
              Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 20,
              ),
                const SizedBox(width: 8),
            ],
            Text(
              text,
                style: const TextStyle(
                  color: Colors.white,
                fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                  fontFamily: '.SF Pro Display',
                ),
              ),
            ],
            ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String count,
    String label,
    IconData icon,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
      children: [
          Icon(icon, color: theme.colorScheme.primary, size: 18),
          const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
              fontSize: 18,
            fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
              fontFamily: '.SF Pro Display',
            ),
          ),
          const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
              fontFamily: '.SF Pro Display',
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildTabsSection(
    BuildContext context,
    UserStatsState statsState,
    int imagesCount,
    int reelsCount,
    int eventsCount,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
            controller: _tabController,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.textTheme.bodySmall?.color,
            labelStyle: const TextStyle(
          fontSize: 14,
              fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: '.SF Pro Display',
            ),
            unselectedLabelStyle: const TextStyle(
          fontSize: 14,
              fontWeight: FontWeight.normal,
          fontFamily: '.SF Pro Display',
            ),
            tabs: [
              Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statsState.isLoading ? '...' : '$imagesCount',
                    style: TextStyle(
                      fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      color: _tabController.index == 0
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      fontFamily: '.SF Pro Display',
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'Images',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.0,
                      color: _tabController.index == 0
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      fontFamily: '.SF Pro Display',
                    ),
                  ),
                  ],
              ),
                ),
              ),
              Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statsState.isLoading ? '...' : '$reelsCount',
                    style: TextStyle(
                      fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      color: _tabController.index == 1
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      fontFamily: '.SF Pro Display',
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'Reels',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.0,
                      color: _tabController.index == 1
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  ],
              ),
                ),
              ),
              Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statsState.isLoading ? '...' : '$eventsCount',
                    style: TextStyle(
                      fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      color: _tabController.index == 2
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      fontFamily: '.SF Pro Display',
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.0,
                      color: _tabController.index == 2
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
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

  Widget _buildContentGrid(BuildContext context) {
    final user = widget.userId != null
        ? _profileUser
        : ref.watch(authProvider.select((state) => state.user));
    final userId = user?.id;

    return TabBarView(
      controller: _tabController,
      children: [
        ProfilePostsGrid(
          filterType: 'image',
          showTextOverlay: true,
          userId: userId,
        ),
        ProfilePostsGrid(
          filterType: 'reel',
          showTextOverlay: true,
          userId: userId,
        ),
        ProfilePostsGrid(
          filterType: 'event',
          showTextOverlay: true,
          userId: userId,
        ),
      ],
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

  Future<void> _handleChatButton(BuildContext context, UserModel user) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a conversation')),
      );
      return;
    }

    if (currentUser.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .createOrGetConversation(user.id);

      if (!context.mounted) return;

      Navigator.of(context).pop();

      if (conversation != null) {
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

      Navigator.of(context).pop();

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

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
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: '.SF Pro Display',
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
}
