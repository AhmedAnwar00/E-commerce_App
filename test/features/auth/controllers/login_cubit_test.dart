import 'package:dio/dio.dart';
import 'package:e_commerce/core/network/api_endpoints.dart';
import 'package:e_commerce/core/network/dio_client.dart';
import 'package:e_commerce/core/network/token_storage.dart';
import 'package:e_commerce/features/auth/data/datasource/loginservice.dart';
import 'package:e_commerce/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:e_commerce/features/auth/presentation/viewmodel/login_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const missingTokensMessage =
      'Login failed. Required authentication tokens were not returned.';

  group('LoginCubit login token validation', () {
    test('emits LoginSuccess when both tokens are present', () async {
      final cubit = _cubit(
        data: const {
          'accessToken': 'access_123',
          'refreshToken': 'refresh_456',
        },
      );
      addTearDown(cubit.close);

      final states = await _login(cubit);

      expect(states, [isA<LoginLoading>(), isA<LoginSuccess>()]);
    });

    test('emits LoginError when a required token is missing', () async {
      final cubit = _cubit(
        data: const {'accessToken': 'access_123'},
      );
      addTearDown(cubit.close);

      final states = await _login(cubit);

      expect(states, [isA<LoginLoading>(), isA<LoginError>()]);
      expect((states.last as LoginError).message, missingTokensMessage);
    });

    test('emits LoginError when a required token is empty', () async {
      final cubit = _cubit(
        data: const {
          'accessToken': '',
          'refreshToken': 'refresh_456',
        },
      );
      addTearDown(cubit.close);

      final states = await _login(cubit);

      expect(states, [isA<LoginLoading>(), isA<LoginError>()]);
      expect((states.last as LoginError).message, missingTokensMessage);
    });
  });
}

LoginCubit _cubit({required Map<String, dynamic> data}) {
  final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
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

  return LoginCubit(
    loginService: LoginService(
      dioClient: DioClient(
        dio: dio,
        tokenStorage: InMemoryTokenStorage(),
        enableLogging: false,
      ),
    ),
  );
}

Future<List<LoginState>> _login(LoginCubit cubit) async {
  final states = <LoginState>[];
  final subscription = cubit.stream.listen(states.add);
  await cubit.login(username: 'emilys', password: 'emilyspass');
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return states;
}
