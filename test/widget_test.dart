import 'package:e_commerce/core/network/dio_client.dart';
import 'package:e_commerce/features/auth/data/datasource/loginservice.dart';
import 'package:e_commerce/features/auth/presentation/views/login.dart';
import 'package:e_commerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen shows sign in button and form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        loginService: LoginService(
          dioClient: DioClient(enableLogging: false),
        ),
      ),
    );

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Your Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
