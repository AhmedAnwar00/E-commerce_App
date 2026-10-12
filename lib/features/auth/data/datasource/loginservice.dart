import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';

/// Service responsible for authentication API calls.
class LoginService {
  final DioClient _dioClient;

  LoginService({required this._dioClient});

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
    final accessToken = _authenticationToken(data['accessToken']);
    final refreshToken = _authenticationToken(data['refreshToken']);

    if (accessToken == null || refreshToken == null) {
      throw const ApiException(
        message:
            'Login failed. Required authentication tokens were not returned.',
      );
    }

    await _dioClient.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return data;
  }
}

String? _authenticationToken(Object? value) {
  if (value == null) {
    return null;
  }

  final token = value.toString();
  if (token.trim().isEmpty) {
    return null;
  }

  return token;
}
