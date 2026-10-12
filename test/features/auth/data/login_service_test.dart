import 'package:dio/dio.dart';
import 'package:e_commerce/core/network/api_endpoints.dart';
import 'package:e_commerce/core/network/api_exceptions.dart';
import 'package:e_commerce/core/network/dio_client.dart';
import 'package:e_commerce/core/network/token_storage.dart';
import 'package:e_commerce/features/auth/data/datasource/loginservice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const username = 'emilys';
  const password = 'emilyspass';
  const missingTokensMessage =
      'Login failed. Required authentication tokens were not returned.';

  group('LoginService.loginUser', () {
    test('saves both tokens when the login response contains them', () async {
      final storage = InMemoryTokenStorage();
      late RequestOptions captured;
      final service = LoginService(
        dioClient: _client(
          storage: storage,
          data: const {
            'accessToken': 'access_123',
            'refreshToken': 'refresh_456',
            'id': 1,
          },
          onRequest: (options) => captured = options,
        ),
      );

      final result = await service.loginUser(
        username: username,
        password: password,
      );

      expect(captured.method, 'POST');
      expect(captured.path, ApiEndpoints.login);
      expect(captured.data, {
        'username': username,
        'password': password,
      });
      expect(captured.extra['requiresAuth'], isFalse);
      expect(result['accessToken'], 'access_123');
      expect(result['refreshToken'], 'refresh_456');
      expect(await storage.getAccessToken(), 'access_123');
      expect(await storage.getRefreshToken(), 'refresh_456');
    });

    test('rejects missing or null tokens and stores nothing', () async {
      final responses = <Map<String, dynamic>>[
        {'refreshToken': 'refresh_456'},
        {'accessToken': 'access_123'},
        {'accessToken': null, 'refreshToken': 'refresh_456'},
        {'accessToken': 'access_123', 'refreshToken': null},
        <String, dynamic>{},
      ];

      for (final data in responses) {
        final storage = InMemoryTokenStorage();
        final service = LoginService(
          dioClient: _client(storage: storage, data: data),
        );

        await expectLater(
          service.loginUser(username: username, password: password),
          throwsA(
            isA<ApiException>()
                .having(
                  (exception) => exception.message,
                  'message',
                  missingTokensMessage,
                )
                .having(
                  (exception) => exception.message,
                  'message',
                  isNot(contains('access_123')),
                )
                .having(
                  (exception) => exception.message,
                  'message',
                  isNot(contains('refresh_456')),
                ),
          ),
        );
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
      }
    });

    test('rejects empty tokens and does not save a partial pair', () async {
      final responses = <Map<String, dynamic>>[
        {'accessToken': '', 'refreshToken': 'refresh_456'},
        {'accessToken': 'access_123', 'refreshToken': ''},
        {'accessToken': '   ', 'refreshToken': 'refresh_456'},
        {'accessToken': 'access_123', 'refreshToken': ' \n '},
        {'accessToken': '', 'refreshToken': ''},
      ];

      for (final data in responses) {
        final storage = InMemoryTokenStorage();
        final service = LoginService(
          dioClient: _client(storage: storage, data: data),
        );

        await expectLater(
          service.loginUser(username: username, password: password),
          throwsA(
            isA<ApiException>().having(
              (exception) => exception.message,
              'message',
              missingTokensMessage,
            ),
          ),
        );
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
      }
    });
  });
}

DioClient _client({
  required InMemoryTokenStorage storage,
  required Map<String, dynamic> data,
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );

  return DioClient(
    dio: dio,
    tokenStorage: storage,
    enableLogging: false,
  );
}
