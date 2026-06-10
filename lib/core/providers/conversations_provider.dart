import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'api_provider.dart';
import 'socket_provider.dart';

class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ApiService _apiService;
  final SocketService _socketService;
  StreamSubscription<Map<String, dynamic>>? _conversationSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  String? _currentUserId;

  ConversationsNotifier(this._apiService, this._socketService)
    : super(ConversationsState()) {
    _setupSocketListeners();
    _loadCurrentUserId();
    // Don't auto-load on creation, let the UI trigger it
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final response = await _apiService.getProfile();
      if (response.data != null) {
        final userData = response.data is Map
            ? response.data as Map<String, dynamic>
            : {'id': null};
        _currentUserId = userData['id'] as String?;
        debugPrint('Loaded current user ID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('Error loading current user ID: $e');
    }
  }

  void _setupSocketListeners() {
    try {
      // Listen for conversation updates
      _conversationSubscription = _socketService.conversationStream.listen((
        event,
      ) {
        debugPrint('Conversation stream event received: ${event['type']}');
        debugPrint('Conversation event data: ${event['data']}');
        if (event['type'] == 'updated') {
          // Handle different data structures from backend
          Map<String, dynamic>? conversationData;
          if (event['data'] is Map) {
            final data = event['data'] as Map<String, dynamic>;
            conversationData =
                data['conversation'] as Map<String, dynamic>? ??
                data as Map<String, dynamic>?;
          }

          if (conversationData != null) {
            try {
              final updatedConversation = ConversationModel.fromJson(
                conversationData,
              );
              debugPrint(
                'Updating conversation from socket: ${updatedConversation.id}, unreadCount: ${updatedConversation.unreadCount}',
              );

              // Update or add conversation to list
              final updatedList = List<ConversationModel>.from(
                state.conversations,
              );
              final index = updatedList.indexWhere(
                (c) => c.id == updatedConversation.id,
              );

              if (index >= 0) {
                updatedList[index] = updatedConversation;
                debugPrint('Updated existing conversation at index $index');
              } else {
                updatedList.insert(0, updatedConversation);
                debugPrint('Added new conversation to list');
              }

              // Sort by last message time (most recent first)
              updatedList.sort((a, b) {
                final aTime = a.lastMessageTime ?? a.updatedAt;
                final bTime = b.lastMessageTime ?? b.updatedAt;
                return bTime.compareTo(aTime);
              });

              state = state.copyWith(conversations: updatedList);
            } catch (e) {
              debugPrint('Error updating conversation from socket: $e');
            }
          } else {
            debugPrint('No conversation data in event');
          }
        }
      });

      // Also listen for new messages to update conversation list
      _messageSubscription = _socketService.messageStream.listen((event) {
        debugPrint('Message stream event received: ${event['type']}');
        if (event['type'] == 'received' || event['type'] == 'sent') {
          final messageData = event['data'] as Map<String, dynamic>?;
          if (messageData != null) {
            final conversationId =
                messageData['conversationId'] as String? ??
                messageData['conversation_id'] as String?;
            final text = messageData['text'] as String?;
            final senderId =
                messageData['senderId'] as String? ??
                messageData['sender_id'] as String?;
            final createdAt = messageData['createdAt'] != null
                ? DateTime.parse(messageData['createdAt'] as String)
                : messageData['created_at'] != null
                ? DateTime.parse(messageData['created_at'] as String)
                : DateTime.now();

            if (conversationId != null && text != null) {
              debugPrint(
                'Updating conversation from message: $conversationId, type: ${event['type']}, senderId: $senderId, currentUserId: $_currentUserId',
              );

              // Find and update conversation
              final updatedList = List<ConversationModel>.from(
                state.conversations,
              );
              final index = updatedList.indexWhere(
                (c) => c.id == conversationId,
              );

              if (index >= 0) {
                // Update existing conversation
                final conversation = updatedList[index];
                final isReceived = event['type'] == 'received';
                // Only increment unread if message is received AND from someone else
                final shouldIncrementUnread =
                    isReceived &&
                    senderId != null &&
                    _currentUserId != null &&
                    senderId != _currentUserId;

                updatedList[index] = ConversationModel(
                  id: conversation.id,
                  userId: conversation.userId,
                  username: conversation.username,
                  displayName: conversation.displayName,
                  avatarUrl: conversation.avatarUrl,
                  lastMessage: text,
                  lastMessageTime: createdAt,
                  unreadCount: shouldIncrementUnread
                      ? conversation.unreadCount + 1
                      : conversation.unreadCount,
                  createdAt: conversation.createdAt,
                  updatedAt: createdAt,
                );
                debugPrint(
                  'Updated conversation at index $index, unreadCount: ${updatedList[index].unreadCount}',
                );
              } else {
                // New conversation - fetch it from the API
                debugPrint(
                  'New conversation detected: $conversationId, fetching details...',
                );
                _fetchConversationById(conversationId);
              }

              // Sort by last message time
              updatedList.sort((a, b) {
                final aTime = a.lastMessageTime ?? a.updatedAt;
                final bTime = b.lastMessageTime ?? b.updatedAt;
                return bTime.compareTo(aTime);
              });

              state = state.copyWith(conversations: updatedList);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error setting up socket listeners: $e');
      // Continue even if socket setup fails
    }
  }

  Future<void> _fetchConversationById(String conversationId) async {
    try {
      debugPrint('Fetching conversation: $conversationId');
      // Refresh conversations to get the new one
      await loadConversations();
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
    }
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadConversations() async {
    if (state.isLoading) {
      debugPrint('Conversations already loading, skipping duplicate call');
      return;
    }

    try {
      debugPrint('Starting to load conversations...');
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getConversations();
      debugPrint('Conversations API response status: ${response.statusCode}');
      debugPrint(
        'Conversations API response data type: ${response.data.runtimeType}',
      );

      // Handle different response formats
      List<dynamic> conversationsData = [];
      if (response.data is List) {
        conversationsData = response.data as List;
        debugPrint(
          'Found ${conversationsData.length} conversations (List format)',
        );
      } else if (response.data is Map &&
          response.data['conversations'] != null) {
        conversationsData = response.data['conversations'] as List;
        debugPrint(
          'Found ${conversationsData.length} conversations (conversations key)',
        );
      } else if (response.data is Map && response.data['data'] != null) {
        conversationsData = response.data['data'] as List;
        debugPrint(
          'Found ${conversationsData.length} conversations (data key)',
        );
      } else if (response.data == null) {
        // Empty response - no conversations yet
        conversationsData = [];
        debugPrint('Empty response - no conversations yet');
      } else {
        debugPrint('Unexpected response format: ${response.data.runtimeType}');
        conversationsData = [];
      }

      final conversations = conversationsData
          .map((json) {
            try {
              return ConversationModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing conversation: $e');
              return null;
            }
          })
          .whereType<ConversationModel>()
          .toList();

      // Sort by last message time (most recent first)
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.updatedAt;
        final bTime = b.lastMessageTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

      debugPrint('Successfully loaded ${conversations.length} conversations');
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        error: null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading conversations: $e');
      debugPrint('Stack trace: $stackTrace');
      // Always reset loading state, even on error
      state = state.copyWith(
        conversations: state.conversations, // Keep existing conversations
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshConversations() async {
    // Reset state before refreshing
    state = state.copyWith(isLoading: true, error: null);
    await loadConversations();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // Check if there's a response with error message
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final responseData = error.response!.data;

        // Try to extract message from response
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? responseData['error'];
          if (message != null) {
            return message.toString();
          }
        }

        // Provide user-friendly messages based on status code
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please check the user ID.';
          case 401:
            return 'Unauthorized. Please log in again.';
          case 404:
            return 'User not found.';
          case 500:
            return 'Server error. Please try again later or contact support.';
          case 503:
            return 'Service temporarily unavailable. Please try again later.';
          default:
            return 'Failed to create conversation. Please try again.';
        }
      }

      // Network or connection errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Connection timeout. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }
    }

    // Fallback to error string
    final errorString = error.toString();
    if (errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }
    return errorString.replaceAll('DioException [bad response]: ', '');
  }

  /// Create or get a conversation with a specific user
  Future<ConversationModel?> createOrGetConversation(String userId) async {
    // Validate userId before making the request
    if (userId.isEmpty || userId.trim().isEmpty) {
      throw Exception('Invalid user ID: user ID cannot be empty');
    }

    // Validate UUID format
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(userId)) {
      throw Exception('Invalid user ID format: must be a valid UUID');
    }

    try {
      debugPrint('Creating/getting conversation with user: $userId');
      debugPrint(
        'User ID format check: ${userId.length} characters, is UUID format: ${uuidRegex.hasMatch(userId)}',
      );

      final response = await _apiService.createConversation(userId);
      debugPrint('Conversation API response status: ${response.statusCode}');
      debugPrint('Conversation API response data: ${response.data}');

      if (response.data != null) {
        Map<String, dynamic> conversationData;
        if (response.data is Map) {
          conversationData = Map<String, dynamic>.from(response.data as Map);
        } else {
          debugPrint(
            'Unexpected response data type: ${response.data.runtimeType}',
          );
          return null;
        }

        debugPrint('Parsing conversation data: $conversationData');
        final conversation = ConversationModel.fromJson(conversationData);
        debugPrint('Created conversation: ${conversation.id}');

        // Add or update in the conversations list
        final updatedList = List<ConversationModel>.from(state.conversations);
        final index = updatedList.indexWhere((c) => c.id == conversation.id);

        if (index >= 0) {
          updatedList[index] = conversation;
        } else {
          updatedList.insert(0, conversation);
        }

        // Sort by last message time
        updatedList.sort((a, b) {
          final aTime = a.lastMessageTime ?? a.updatedAt;
          final bTime = b.lastMessageTime ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

        state = state.copyWith(conversations: updatedList);
        return conversation;
      }
      debugPrint('No conversation data in response');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error creating/getting conversation: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback: If server error (500), try to find existing conversation
      if (e is DioException && e.response?.statusCode == 500) {
        debugPrint(
          'Server error detected, checking for existing conversation...',
        );

        // Try to find existing conversation with this user
        try {
          final existingConversation = state.conversations.firstWhere(
            (conv) => conv.userId == userId,
          );

          debugPrint('Found existing conversation: ${existingConversation.id}');
          return existingConversation;
        } catch (_) {
          // Conversation not found in current list
          debugPrint('Conversation not found in current list');
        }

        // If conversations list is empty, try loading conversations first
        if (state.conversations.isEmpty) {
          debugPrint('Conversations list empty, attempting to load...');
          try {
            await loadConversations();

            // Try again after loading
            try {
              final foundConversation = state.conversations.firstWhere(
                (conv) => conv.userId == userId,
              );

              debugPrint(
                'Found conversation after loading: ${foundConversation.id}',
              );
              return foundConversation;
            } catch (_) {
              debugPrint('Conversation still not found after loading');
            }
          } catch (loadError) {
            debugPrint('Error loading conversations for fallback: $loadError');
          }
        }
      }

      // Extract user-friendly error message
      final errorMessage = _extractErrorMessage(e);

      // Create a custom exception with the friendly message
      throw Exception(errorMessage);
    }
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final socketService = ref.watch(socketServiceProvider);
      return ConversationsNotifier(apiService, socketService);
    });
