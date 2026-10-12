import 'package:e_commerce/core/network/dio_client.dart';
import 'package:e_commerce/features/auth/data/datasource/loginservice.dart';
import 'package:e_commerce/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:e_commerce/features/auth/presentation/views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';

void main() {
  final dioClient = DioClient();
  final loginService = LoginService(dioClient: dioClient);
  runApp(MyApp(loginService: loginService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.loginService});

  final LoginService loginService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce',
      theme: AppTheme.light,
      home: BlocProvider(
        create: (_) => LoginCubit(loginService: loginService),
        child: const LoginView(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
