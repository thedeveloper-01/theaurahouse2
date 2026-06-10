// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, unnecessary_underscores

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_stats_provider.dart';
import '../../../core/widgets/glass_container.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late final MediaService _mediaService;
  final List<File> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _mediaService = MediaService();
    // Auto-focus text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _mediaService.pickMultipleImages();
    if (mounted) {
      setState(() {
        _selectedFiles.addAll(images);
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _mediaService.pickVideo();
    if (video != null && mounted) {
      setState(() {
        _selectedFiles.clear(); // Only one video allowed
        _selectedFiles.add(video);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (_selectedFiles.isEmpty && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add text or media to create a post'),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Compress images
      final List<String> filePaths = [];
      int processed = 0;

      for (var file in _selectedFiles) {
        final fileExtension = file.path.toLowerCase();
        if (fileExtension.endsWith('.jpg') ||
            fileExtension.endsWith('.jpeg') ||
            fileExtension.endsWith('.png')) {
          final compressed = await _mediaService.compressImage(file);
          if (compressed != null) {
            filePaths.add(compressed.path);
          } else {
            filePaths.add(file.path);
          }
        } else {
          filePaths.add(file.path);
        }

        processed++;
        if (mounted) {
          setState(() {
            _uploadProgress =
                processed / _selectedFiles.length * 0.7; // 70% for processing
          });
        }
      }

      if (mounted) {
        setState(() {
          _uploadProgress = 0.8; // 80% for uploading
        });
      }

      await ref
          .read(postsProvider.notifier)
          .createPost(
            text: _textController.text.trim().isEmpty
                ? null
                : _textController.text.trim(),
            filePaths: filePaths,
          );

      // Refresh user stats after creating post
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(userStatsProvider(currentUser.id).notifier)
            .refresh(currentUser.id);
      }

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 300));

        // Navigate to homepage instead of just popping
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false, // Remove all previous routes
        );

        // Show success message after navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 12),
                const Text('Post created successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: theme.iconTheme.color),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
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
              'Create Post',
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PostButton(onPressed: _createPost),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input section
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  blur: 15,
                  opacity: 0.1,
                  color: theme.colorScheme.surface,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontFamily: '.SF Pro Display',
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 6,
                    textInputAction: TextInputAction.newline,
                  ),
                ),

                const SizedBox(height: 24),

                // Media preview section
                if (_selectedFiles.isNotEmpty) ...[
                  Text(
                    'Media Preview',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final isVideo =
                            file.path.toLowerCase().endsWith('.mp4') ||
                            file.path.toLowerCase().endsWith('.mov') ||
                            file.path.toLowerCase().endsWith('.avi');

                        return _MediaPreviewItem(
                          file: file,
                          isVideo: isVideo,
                          onRemove: () => _removeFile(index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Media picker buttons
                Text(
                  'Add Media',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MediaPickerButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Photos',
                        color: const Color(0xFF8B5CF6),
                        onTap: _pickImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MediaPickerButton(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        color: const Color(0xFF6366F1),
                        onTap: _pickVideo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),

          // Upload progress overlay
          if (_isUploading)
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                return Positioned.fill(
              child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                child: Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32),
                    borderRadius: BorderRadius.circular(24),
                    blur: 20,
                    opacity: 0.2,
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                            CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                            Text(
                          'Uploading...',
                          style: TextStyle(
                      fontFamily: '.SF Pro Display',
                                color: theme.textTheme.titleLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_uploadProgress > 0)
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_uploadProgress > 0)
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: TextStyle(
                      fontFamily: '.SF Pro Display',
                                  color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
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

class _MediaPreviewItem extends StatelessWidget {
  final File file;
  final bool isVideo;
  final VoidCallback onRemove;

  const _MediaPreviewItem({
    required this.file,
    required this.isVideo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isVideo
                ? Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.scaffoldBackgroundColor,
                            child: Icon(
                              Icons.videocam_rounded,
                              color: theme.iconTheme.color?.withValues(
                                alpha: 0.5,
                              ),
                              size: 48,
                            ),
                          ),
                        ),
                        Container(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.3),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: theme.colorScheme.onSurface,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Icon(
                        Icons.image_not_supported,
                        color: theme.iconTheme.color?.withValues(alpha: 0.5),
                        size: 48,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface,
                size: 18,
              ),
            ),
          ),
        ),
        if (isVideo)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: theme.colorScheme.onSurface,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      color: theme.colorScheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        borderRadius: BorderRadius.circular(16),
        blur: 15,
        opacity: 0.1,
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PostButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Post',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
