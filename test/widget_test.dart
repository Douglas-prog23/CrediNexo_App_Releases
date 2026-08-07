import 'package:credinexo/features/auth/data/auth_api.dart';
import 'package:credinexo/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login page renders Credinexo access form',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(onLogin: (AuthSession _) async {}),
      ),
    );

    expect(find.text('Credinexo'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
  });
}
