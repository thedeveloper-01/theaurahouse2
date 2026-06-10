import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';

class ApiService {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  ApiService(this._secureStorage) {
    // Ensure baseUrl has no trailing/leading spaces
    final baseUrl = ApiConstants.baseUrl.trim();
    AppLogger.info('API Base URL configured', baseUrl);

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(
          seconds: 15,
        ), // Reasonable timeout for most requests
        sendTimeout: const Duration(seconds: 30), // Increased for file uploads
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLogger.api(
            options.method,
            options.path,
          );
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized - clear token
            await _secureStorage.deleteAuthToken();
          }
          AppLogger.error(
            'API Error: ${error.response?.statusCode}',
            error.message,
          );
          handler.next(error);
        },
      ),
    );
  }

  // Auth methods
  Future<Response> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _dio.post(
      ApiConstants.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      },
    );
  }

  Future<Response> login({
    required String username,
    required String password,
  }) async {
    return await _dio.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );
  }

  Future<Response> getProfile({Duration? timeout}) async {
    return await _dio.get(
      ApiConstants.profile,
      options: Options(
        receiveTimeout: timeout ?? const Duration(seconds: 5),
        sendTimeout: timeout ?? const Duration(seconds: 5),
      ),
    );
  }

  // Posts methods
  Future<Response> getPosts({
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    return await _dio.get(
      ApiConstants.posts,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (userId != null) 'userId': userId,
      },
    );
  }

  Future<Response> getPost(String id) async {
    return await _dio.get(ApiConstants.postById(id));
  }

  Future<Response> createPost({
    String? text,
    String? privacy,
    required List<String> filePaths,
  }) async {
    try {
      final formData = FormData();
      if (text != null && text.isNotEmpty) {
        formData.fields.add(MapEntry('text', text));
      }
      if (privacy != null) {
        formData.fields.add(MapEntry('privacy', privacy));
      }

      // Add files with proper error handling
      for (var filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File not found: $filePath');
        }

        final fileSize = await file.length();
        AppLogger.debug(
          'Uploading file',
          '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );

        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              filePath,
              filename: path.basename(filePath),
            ),
          ),
        );
      }

      AppLogger.debug('Uploading post', '${filePaths.length} file(s)');

      final response = await _dio.post(
        ApiConstants.posts,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 120), // 2 minutes for upload
          receiveTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = (sent / total * 100).toStringAsFixed(1);
            AppLogger.debug('Upload progress', '$progress%');
          }
        },
      );

      AppLogger.info('Post uploaded successfully');
      return response;
    } catch (e) {
      AppLogger.error('Error uploading post', e);
      rethrow;
    }
  }

  Future<Response> updatePost(String id, {String? text}) async {
    return await _dio.patch(
      ApiConstants.postById(id),
      data: {if (text != null) 'text': text},
    );
  }

  Future<Response> deletePost(String id) async {
    return await _dio.delete(ApiConstants.postById(id));
  }

  // Comments methods
  Future<Response> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await _dio.get(
      ApiConstants.commentsByPost(postId),
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  Future<Response> createComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    return await _dio.post(
      ApiConstants.createComment(postId),
      data: {
        'text': text,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );
  }

  Future<Response> updateComment(String id, String text) async {
    return await _dio.patch(ApiConstants.commentById(id), data: {'text': text});
  }

  Future<Response> deleteComment(String id) async {
    return await _dio.delete(ApiConstants.commentById(id));
  }

  // Likes methods
  Future<Response> toggleLike(String postId) async {
    return await _dio.post(ApiConstants.toggleLike(postId));
  }

  Future<Response> checkLike(String postId) async {
    return await _dio.get(ApiConstants.checkLike(postId));
  }

  // Users methods
  Future<Response> getUser(String id) async {
    return await _dio.get(ApiConstants.userById(id));
  }

  Future<Response> getUserByUsername(String username) async {
    return await _dio.get(ApiConstants.userByUsername(username));
  }

  Future<Response> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    return await _dio.put(
      ApiConstants.updateProfile,
      data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
  }

  Future<Response> getUserStats(String userId) async {
    return await _dio.get(ApiConstants.userStats(userId));
  }

  // Search users by username query - returns list of users matching the query
  Future<Response> searchUsers(String query) async {
    return await _dio.get(
      ApiConstants.searchUsers,
      queryParameters: {'q': query, 'limit': 20},
    );
  }

  // Conversations/Messages methods
  Future<Response> getConversations() async {
    return await _dio.get(ApiConstants.conversations);
  }

  Future<Response> getConversation(String conversationId) async {
    return await _dio.get(ApiConstants.conversationById(conversationId));
  }

  Future<Response> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    return await _dio.get(
      ApiConstants.messagesByConversation(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  Future<Response> createConversation(String userId) async {
    AppLogger.debug('Creating conversation with userId', userId);

    // Ensure userId is not null or empty
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    // Prepare request data
    final requestData = {'userId': userId};

    try {
      final response = await _dio.post(
        ApiConstants.conversations,
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      AppLogger.debug('Create conversation response', response.statusCode);
      return response;
    } catch (e) {
      if (e is DioException && e.response != null) {
        AppLogger.error(
          'Create conversation error: ${e.response?.statusCode}',
          e.response?.data,
        );
      }
      rethrow;
    }
  }

  Future<Response> sendMessage(String conversationId, String text) async {
    AppLogger.debug('Sending message to conversation', conversationId);

    try {
      final response = await _dio.post(
        ApiConstants.messagesByConversation(conversationId),
        data: {'text': text},
      );
      AppLogger.debug('Send message response', response.statusCode);
      return response;
    } catch (e) {
      if (e is DioException && e.response != null) {
        AppLogger.error(
          'Send message error: ${e.response?.statusCode}',
          e.response?.data,
        );
      }
      rethrow;
    }
  }

  Future<Response> markConversationAsRead(String conversationId) async {
    return await _dio.post(
      '${ApiConstants.conversationById(conversationId)}/read',
    );
  }
}
