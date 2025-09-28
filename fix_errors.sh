#!/bin/bash

echo "🔧 Corrigindo erros do projeto Flutter..."

# 1. Criar diretórios de assets
echo "📁 Criando diretórios de assets..."
mkdir -p assets/images
mkdir -p assets/animations
mkdir -p assets/icons

# 2. Corrigir o arquivo de teste
echo "✏️ Corrigindo arquivo de teste..."
cat > test/widget_test.dart << 'ENDTEST'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_tarefas_kids/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstTime: true));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
ENDTEST

echo "✅ Correções básicas aplicadas!"
