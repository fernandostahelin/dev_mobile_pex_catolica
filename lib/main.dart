import 'package:flutter/material.dart';
import 'telas/area_cliente_sem_login.dart';
import 'telas/cadastro_tela.dart';
import 'telas/login_tela.dart';
import 'telas/inicio_tela.dart';
import 'telas/area_cliente_logado_tela.dart';
import 'telas/informacoes_tela.dart';
import 'telas/documentos_tela.dart';

void main() {
  runApp(const PexApp());
}

class PexApp extends StatelessWidget {
  const PexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PEX - Área do Cliente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      initialRoute: '/area-cliente-sem-login',
      routes: {
        '/area-cliente-sem-login': (context) => const AreaClienteSemLogin(),
        '/cadastro': (context) => const CadastroTela(),
        '/login': (context) => const LoginTela(),
        '/inicio': (context) => const InicioTela(),
        '/area-cliente-logado': (context) => const AreaClienteLogadoTela(),
        '/informacoes': (context) => const InformacoesTela(),
        '/documentos': (context) => const DocumentosTela(),
      },
    );
  }
}
