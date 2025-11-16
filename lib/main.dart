import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/area_cliente_sem_login.dart';
import 'telas/cadastro_tela.dart';
import 'telas/login_tela.dart';
import 'telas/inicio_tela.dart';
import 'telas/area_cliente_logado_tela.dart';
import 'telas/informacoes_tela.dart';
import 'telas/documentos_tela.dart';
import 'telas/admin_panel_tela.dart';
import 'telas/adicionar_propriedade_tela.dart';
import 'modelos/propriedade.dart';
import 'widgets/erro_widget.dart';
import 'servicos/erro_service.dart';

void main() async {
  // Garante que o Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configura o manipulador de erros global do Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log do erro em modo debug
    ErroService.logErro(details.exception, details.stack);
    
    // Apresenta o erro customizado ao usuário
    FlutterError.presentError(details);
  };

  // Configura o manipulador de erros para erros fora do Flutter (async)
  PlatformDispatcher.instance.onError = (error, stack) {
    ErroService.logErro(error, stack);
    return true;
  };

  // Configura o widget de erro customizado
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErroWidget(errorDetails: details);
  };

  // Executa o app dentro de uma zona para capturar erros assíncronos
  runZonedGuarded(
    () async {
      await Firebase.initializeApp();
      runApp(const PexApp());
    },
    (error, stackTrace) {
      ErroService.logErro(error, stackTrace);
    },
  );
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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      initialRoute: '/inicio',
      routes: {
        '/inicio': (context) => const InicioTela(),
        '/area-cliente-sem-login': (context) => const AreaClienteSemLogin(),
        '/cadastro': (context) => const CadastroTela(),
        '/login': (context) => const LoginTela(),
        '/area-cliente-logado': (context) => const AreaClienteLogadoTela(),
        '/informacoes': (context) => const InformacoesTela(),
        '/documentos': (context) => const DocumentosTela(),
        '/admin-panel': (context) => const AdminPanelTela(),
        '/adicionar-propriedade': (context) => const AdicionarPropriedadeTela(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/editar-propriedade') {
          final propriedade = settings.arguments as Propriedade;
          return MaterialPageRoute(
            builder: (context) =>
                AdicionarPropriedadeTela(propriedade: propriedade),
          );
        }
        return null;
      },
    );
  }
}
