import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_tarefas_kids/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstTime: true));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
