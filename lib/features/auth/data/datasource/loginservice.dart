import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

/// Service responsible for authentication API calls.
class LoginService {
  final DioClient _dioClient;

  LoginService({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  /// Logs in a user using [username] and [password].
  ///
  /// On successful authentication, automatically stores the returned
  /// [accessToken] and [refreshToken] in [DioClient].
  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
      requiresAuth: false, // Login endpoint is public
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    // Save tokens if available in response
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();

    if (accessToken != null && refreshToken != null) {
      await _dioClient.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return data;
  }
}

/// Top-level singleton helper for convenient access.
final LoginService loginService = LoginService();

/// Backward-compatible helper matching previous function signature.
Future<void> login(Map<String, String> body) async {
  await loginService.loginUser(

    username: body['username'] ?? '',
    password: body['password'] ?? '',
    //
    
  );
}
