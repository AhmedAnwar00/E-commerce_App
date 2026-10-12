/// Contract for storing and retrieving authentication tokens.
///
/// You can implement this interface with [InMemoryTokenStorage] for in-memory,
/// or with `flutter_secure_storage` / `shared_preferences` for persistent storage.
abstract class TokenStorage {
  /// Returns the current access token, or null if not set.
  Future<String?> getAccessToken();

  /// Returns the current refresh token, or null if not set.
  Future<String?> getRefreshToken();

  /// Persists both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Clears stored tokens (e.g., on logout or expired refresh token).
  Future<void> clearTokens();

  /// Checks if a valid access token exists.
  Future<bool> hasAccessToken();
}

/// Default in-memory implementation of [TokenStorage].
///
/// Useful for quick testing, session-only tokens, or default client setups.
class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  InMemoryTokenStorage({
    this._accessToken,
    this._refreshToken,
  });

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasAccessToken() async =>
      _accessToken != null && _accessToken!.isNotEmpty;
}
