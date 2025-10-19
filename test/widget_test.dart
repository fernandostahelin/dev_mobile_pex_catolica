// Teste básico para o app PEX
//
// Este é um teste simples para verificar se o app inicia corretamente
// e se a tela inicial é exibida.

import 'package:flutter_test/flutter_test.dart';

import 'package:pex/main.dart';

void main() {
  testWidgets('App inicia e mostra tela Área do Cliente', (
    WidgetTester tester,
  ) async {
    // Constrói o app e dispara um frame.
    await tester.pumpWidget(const PexApp());

    // Verifica se o título "Área do Cliente" está presente na tela principal.
    expect(find.text('Área do Cliente'), findsAtLeastNWidgets(1));

    // Verifica se os botões estão presentes.
    expect(find.text('Não sou cliente'), findsOneWidget);
    expect(find.text('Já sou cliente'), findsOneWidget);
  });
}
