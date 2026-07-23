import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learner_verification_app/screens/login_screen.dart';
import 'package:learner_verification_app/theme/app_theme.dart';

void main() {
  testWidgets('Login screen renders the Salesforce login button', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const LoginScreen()));

    expect(find.text('DM Login'), findsOneWidget);
    expect(find.text('Log In with Salesforce'), findsOneWidget);
  });
}
