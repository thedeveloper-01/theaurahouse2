// ignore_for_file: library_prefixes

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  final SecureStorageService _secureStorage;
  
  late final StreamController<Map<String, dynamic>> _messageController;
  late final StreamController<Map<String, dynamic>> _conversationController;
  late final StreamController<Map<String, dynamic>> _typingController;

  SocketService(this._secureStorage) {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _conversationController = StreamController<Map<String, dynamic>>.broadcast();
    _typingController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get conversationStream =>
      _conversationController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    try {
      final token = await _secureStorage.getAuthToken();

      if (token == null) {
        AppLogger.warning('No auth token found, cannot connect socket');
        return;
      }

      // Get base URL without trailing slash
      final baseUrl = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(500) // Faster reconnection
            .setReconnectionDelayMax(3000) // Max 3 seconds
            .setReconnectionAttempts(10) // More attempts
            .setTimeout(10000) // Faster timeout
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        _isConnected = true;
        AppLogger.info('Socket connected');
      });

      // Listen for authenticated event (backend emits this instead of 'connect')
      _socket!.on('authenticated', (data) {
        _isConnected = true;
        AppLogger.info('Socket authenticated', data);
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        AppLogger.info('Socket disconnected');
      });

      _socket!.onError((error) {
        AppLogger.error('Socket error', error);
        _isConnected = false;
      });

      // Also check connection status periodically for reliability
      _socket!.on('connect_error', (error) {
        AppLogger.error('Socket connection error', error);
        _isConnected = false;
      });

      // Listen for message events (optimized for speed)
      _socket!.on('message:sent', (data) {
        if (!_messageController.isClosed) {
          final messageData = data is Map ? (data['message'] ?? data) : data;
          _messageController.add({'type': 'sent', 'data': messageData});
        }
      });

      _socket!.on('message:received', (data) {
        if (!_messageController.isClosed) {
          final messageData = data is Map ? (data['message'] ?? data) : data;
          _messageController.add({'type': 'received', 'data': messageData});
        }
      });

      // Also listen for generic message event
      _socket!.on('message:new', (data) {
        if (!_messageController.isClosed) {
          final messageData = data is Map ? (data['message'] ?? data) : data;
          _messageController.add({'type': 'received', 'data': messageData});
        }
      });

      // Listen for conversation updates
      _socket!.on('conversation:updated', (data) {
        if (!_conversationController.isClosed) {
          _conversationController.add({'type': 'updated', 'data': data});
        }
      });

      // Listen for typing indicators
      _socket!.on('typing:start', (data) {
        if (!_typingController.isClosed) {
          _typingController.add({'type': 'start', 'data': data});
        }
      });

      _socket!.on('typing:stop', (data) {
        if (!_typingController.isClosed) {
          _typingController.add({'type': 'stop', 'data': data});
        }
      });
    } catch (e) {
      AppLogger.error('Error connecting socket', e);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void sendMessage(String conversationId, String text) {
    final isActuallyConnected =
        _socket != null && (_socket!.connected || _isConnected);

    if (isActuallyConnected) {
      _socket!.emit('message:send', {
        'conversationId': conversationId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      AppLogger.debug('Message sent via socket', conversationId);
    } else {
      AppLogger.warning('Socket not connected, cannot send message');
    }
  }

  void joinConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('conversation:join', {'conversationId': conversationId});
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('conversation:leave', {'conversationId': conversationId});
    }
  }

  void startTyping(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing:start', {'conversationId': conversationId});
    }
  }

  void stopTyping(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing:stop', {'conversationId': conversationId});
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _conversationController.close();
    _typingController.close();
  }
}
