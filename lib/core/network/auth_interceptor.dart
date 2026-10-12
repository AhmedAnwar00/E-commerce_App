import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'token_storage.dart';

/// Callback invoked when refresh token fails or user is unauthenticated.
typedef OnUnauthorizedCallback = void Function();

/// Callback invoked whenever tokens are refreshed successfully.
typedef OnTokenRefreshedCallback = void Function(
  String newAccessToken,
  String newRefreshToken,
);

/// A [QueuedInterceptor] that automatically manages Authorization headers,
/// injects Bearer tokens, and transparently refreshes expired access tokens
/// when encountering a 401 Unauthorized response.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio _refreshDio;
  final String refreshEndpoint;
  final OnUnauthorizedCallback? onUnauthorized;
  final OnTokenRefreshedCallback? onTokenRefreshed;

  AuthInterceptor({
    required this.tokenStorage,
    Dio? refreshDio,
    this.refreshEndpoint = ApiEndpoints.refresh,
    this.onUnauthorized,
    this.onTokenRefreshed,
  }) : _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: ApiEndpoints.connectTimeout,
                receiveTimeout: ApiEndpoints.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {

    // Check if the request explicitly disables authentication
    final bool requiresAuth = options.extra['requiresAuth'] ?? true;
//if 401 == request 
    if (requiresAuth) {
      final accessToken = await tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;
    final isRetry = err.requestOptions.extra['isRetry'] == true;
    final requiresAuth = err.requestOptions.extra['requiresAuth'] ?? true;

    // Handle token refresh only on 401, if not already retried, and if auth was required
    if (isUnauthorized && !isRetry && requiresAuth) {
      final refreshToken = await tokenStorage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt refreshing the token using a isolated Dio instance
          final refreshResponse = await _refreshDio.post(
            refreshEndpoint,
            data: {
              'refreshToken': refreshToken,
              'expiresInMins': 30,
            },
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data;
            final newAccessToken = (data['accessToken'] ??
                    data['access_token'] ??
                    data['token'])
                ?.toString();
            final newRefreshToken = (data['refreshToken'] ??
                    data['refresh_token'] ??
                    refreshToken)
                ?.toString();

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              // 1. Save new tokens to storage
              await tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken ?? refreshToken,
              );

              // 2. Notify callback
              onTokenRefreshed?.call(
                newAccessToken,
                newRefreshToken ?? refreshToken,
              );

              // 3. Clone original request options and update headers
              final requestOptions = err.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              requestOptions.extra['isRetry'] = true;

              // 4. Retry the failed request with the fresh token
              final retryResponse = await _refreshDio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (refreshError) {
          // Refresh token has expired or is invalid
          await tokenStorage.clearTokens();
          onUnauthorized?.call();
          return handler.next(err);
        }
      } else {
        // No refresh token available in storage
        await tokenStorage.clearTokens();
        onUnauthorized?.call();
      }
    }

    return handler.next(err);
  }
}
