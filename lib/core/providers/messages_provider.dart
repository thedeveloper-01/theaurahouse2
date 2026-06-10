import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'api_provider.dart';
import 'socket_provider.dart';

class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final bool isTyping;
  final String? typingUserId;

  MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.isTyping = false,
    this.typingUserId,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool? isTyping,
    String? typingUserId,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiService _apiService;
  final SocketService _socketService;
  final String conversationId;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingTimer;
  bool _isDisposed = false;

  MessagesNotifier(this._apiService, this._socketService, this.conversationId)
    : super(MessagesState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _messageSubscription = _socketService.messageStream.listen((event) {
      if (_isDisposed) return;
      if (event['type'] == 'received' || event['type'] == 'sent') {
        final messageData = event['data'] as Map<String, dynamic>?;
        if (messageData != null) {
          final message = MessageModel.fromJson(messageData);

          // Only add if it belongs to this conversation
          if (message.conversationId == conversationId) {
            // Check if message already exists by ID (most reliable)
            final existingIndex = state.messages.indexWhere(
              (m) => m.id == message.id,
            );

            if (existingIndex >= 0) {
              // Message with this ID already exists, update it (might have more complete data)
              if (_isDisposed) return;
              final updatedMessages = List<MessageModel>.from(state.messages);
              updatedMessages[existingIndex] = message;
              updatedMessages.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );
              state = state.copyWith(messages: updatedMessages);
              debugPrint('Message updated (same ID): ${message.id}');
            } else {
              // Check if there's an optimistic message with matching content that should be replaced
              final optimisticIndex = state.messages.indexWhere(
                (m) =>
                    m.id.startsWith('temp_') &&
                    m.text == message.text &&
                    m.senderId == message.senderId &&
                    m.conversationId == message.conversationId &&
                    (m.createdAt.difference(message.createdAt).inSeconds.abs() <
                        5),
              );

              if (optimisticIndex >= 0) {
                // Replace optimistic message with real one
                if (_isDisposed) return;
                final updatedMessages = List<MessageModel>.from(state.messages);
                updatedMessages[optimisticIndex] = message;
                updatedMessages.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );
                state = state.copyWith(messages: updatedMessages);
                debugPrint(
                  'Optimistic message replaced with real message: ${message.id}',
                );
              } else {
                // Check for duplicate by content (different ID but same content)
                final existsByContent = state.messages.any(
                  (m) =>
                      !m.id.startsWith(
                        'temp_',
                      ) && // Don't check against optimistic messages
                      m.text == message.text &&
                      m.senderId == message.senderId &&
                      m.conversationId == message.conversationId &&
                      (m.createdAt
                              .difference(message.createdAt)
                              .inSeconds
                              .abs() <
                          2),
                );

                if (!existsByContent) {
                  // New message, add it
                  if (_isDisposed) return;
                  final updatedMessages = [message, ...state.messages];
                  updatedMessages.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                  state = state.copyWith(messages: updatedMessages);
                  debugPrint('New message added: ${message.id}');
                } else {
                  debugPrint(
                    'Duplicate message detected (by content), skipping: ${message.id}',
                  );
                }
              }
            }
          }
        }
      }
    });

    // Listen for typing indicators
    _typingSubscription = _socketService.typingStream.listen((event) {
      if (_isDisposed) return;
      final data = event['data'] as Map<String, dynamic>?;
      if (data != null && data['conversationId'] == conversationId) {
        if (event['type'] == 'start') {
          if (_isDisposed) return;
          state = state.copyWith(
            isTyping: true,
            typingUserId: data['userId'] as String?,
          );

          // Auto-stop typing after 3 seconds
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (_isDisposed) return;
            state = state.copyWith(isTyping: false, typingUserId: null);
          });
        } else if (event['type'] == 'stop') {
          if (_isDisposed) return;
          _typingTimer?.cancel();
          state = state.copyWith(isTyping: false, typingUserId: null);
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (_isDisposed) return;
    if (state.isLoading && !refresh) return;

    try {
      if (refresh) {
        if (_isDisposed) return;
        state = state.copyWith(isLoading: true, error: null, currentPage: 1);
      } else {
        if (_isDisposed) return;
        state = state.copyWith(isLoadingMore: true, error: null);
      }

      final page = refresh ? 1 : state.currentPage;
      final response = await _apiService.getMessages(
        conversationId,
        page: page,
        limit: 50,
      );

      List<MessageModel> newMessages = [];
      if (response.data is List) {
        newMessages = (response.data as List)
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map && response.data['messages'] != null) {
        newMessages = (response.data['messages'] as List)
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map && response.data['data'] != null) {
        newMessages = (response.data['data'] as List)
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Sort by creation time (newest first)
      newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final allMessages = refresh
          ? newMessages
          : [...state.messages, ...newMessages];

      // Remove duplicates
      final uniqueMessages = <String, MessageModel>{};
      for (var msg in allMessages) {
        uniqueMessages[msg.id] = msg;
      }
      final finalMessages = uniqueMessages.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (_isDisposed) return;
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
        isLoadingMore: false,
        hasMore: newMessages.length >= 50,
        currentPage: page + 1,
        error: null,
      );
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String text, UserModel currentUser) async {
    if (text.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUser.id,
      receiverId: '', // Will be set by server
      text: text.trim(),
      isRead: false,
      createdAt: DateTime.now(),
      sender: {
        'id': currentUser.id,
        'username': currentUser.username,
        'displayName': currentUser.displayName,
        'avatarUrl': currentUser.avatarUrl,
      },
    );

    // Add optimistic message
    if (_isDisposed) return;
    state = state.copyWith(messages: [optimisticMessage, ...state.messages]);

    // Check if socket is connected
    final isSocketConnected = _socketService.isConnected;

    if (isSocketConnected) {
      // Send via socket only - backend will emit it back
      try {
        _socketService.sendMessage(conversationId, text.trim());
        debugPrint('Message sent via socket, waiting for socket response...');
        // Don't send via API - socket will handle it
        // The optimistic message will be replaced when socket emits the real message
      } catch (e) {
        debugPrint('Socket send error, falling back to API: $e');
        // Fallback to API if socket fails
        await _sendViaApi(conversationId, text.trim(), tempId);
      }
    } else {
      // Socket not connected, use API
      debugPrint('Socket not connected, sending via API...');
      await _sendViaApi(conversationId, text.trim(), tempId);
    }
  }

  Future<void> _sendViaApi(
    String conversationId,
    String text,
    String tempId,
  ) async {
    try {
      await _apiService.sendMessage(conversationId, text);
      debugPrint('Message sent via API successfully');

      // Remove optimistic message after a short delay to allow socket to catch up
      // If socket is working, it will replace it; if not, we'll reload messages
      Future.delayed(const Duration(milliseconds: 500), () {
        final currentMessages = state.messages;
        final hasRealMessage = currentMessages.any(
          (m) =>
              m.text == text &&
              m.conversationId == conversationId &&
              !m.id.startsWith('temp_'),
        );

        if (hasRealMessage) {
          // Real message received, remove optimistic
          state = state.copyWith(
            messages: currentMessages.where((m) => m.id != tempId).toList(),
          );
        }
      });
    } catch (e) {
      debugPrint('API send message error: $e');
      // Remove optimistic message on error
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempId).toList(),
      );
    }
  }

  Future<void> markAsRead() async {
    if (_isDisposed) return;
    try {
      await _apiService.markConversationAsRead(conversationId);

      if (_isDisposed) return;
      // Update local state
      final updatedMessages = state.messages.map((msg) {
        if (!msg.isRead) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      if (_isDisposed) return;
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  void startTyping() {
    _socketService.startTyping(conversationId);
  }

  void stopTyping() {
    _socketService.stopTyping(conversationId);
  }
}

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((
      ref,
      conversationId,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      final socketService = ref.watch(socketServiceProvider);
      return MessagesNotifier(apiService, socketService, conversationId);
    });
