import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doc_intelligence/app/core/app_config.dart';
import 'package:doc_intelligence/main.dart';

void main() {
  testWidgets('DOC Intelligence smoke test - renders ClientListPage', (WidgetTester tester) async {
    // Configura tamanho de tela de desktop para o teste
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Força uso do repositório mock nos testes
    AppConfig.useMockRepository = true;

    await tester.pumpWidget(const DocIntelligenceApp());
    await tester.pump(const Duration(milliseconds: 700));

    // Verifica elementos do cabeçalho e título
    expect(find.text('DOC Intelligence'), findsOneWidget);
    expect(find.text('Clientes Cadastrados'), findsOneWidget);
    expect(find.text('Novo Cliente'), findsOneWidget);
  });
}
