class ApiConstants {
  // Update this with your Render backend URL
  // IMPORTANT: Make sure there are NO spaces in the URL
  static const String baseUrl = 'https://thtest-y56g.onrender.com';

  // Verify the URL format:
  // - Starts with https://
  // - No spaces anywhere
  // - Matches your Render service name exactly

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';

  // Posts endpoints
  static const String posts = '/posts';
  static String postById(String id) => '/posts/$id';

  // Comments endpoints
  static String commentsByPost(String postId) => '/comments/post/$postId';
  static String createComment(String postId) => '/comments/post/$postId';
  static String commentById(String id) => '/comments/$id';

  // Likes endpoints
  static String toggleLike(String postId) => '/likes/post/$postId';
  static String checkLike(String postId) => '/likes/post/$postId/check';
  static String likesByPost(String postId) => '/likes/post/$postId';

  // Users endpoints
  static String userById(String id) => '/users/$id';
  static String userByUsername(String username) => '/users/username/$username';
  static const String updateProfile = '/users/profile';
  static String userStats(String id) => '/users/$id/stats';
  static const String searchUsers = '/users/search';

  // Messages/Conversations endpoints
  static const String conversations = '/conversations';
  static String conversationById(String id) => '/conversations/$id';
  static String messagesByConversation(String conversationId) =>
      '/conversations/$conversationId/messages';
}
