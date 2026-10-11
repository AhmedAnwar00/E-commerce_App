import 'package:e_commerce/core/network/api_exceptions.dart';
import 'package:e_commerce/features/auth/data/datasource/loginservice.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required LoginService loginService})
      : _loginService = loginService,
        super(const LoginInitial());

  final LoginService _loginService;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (state is LoginLoading) {
      return;
    }

    emit(const LoginLoading());

    try {
      await _loginService.loginUser(
        username: username,
        password: password,
      );
      emit(const LoginSuccess());
    } on ApiException catch (exception) {
      emit(LoginError(exception.message));
    } catch (_) {
      emit(const LoginError('Something went wrong. Please try again.'));
    }
  }
}
