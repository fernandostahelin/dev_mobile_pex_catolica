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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
            builder: (context) => AdicionarPropriedadeTela(propriedade: propriedade),
          );
        }
        return null;
      },
    );
  }
}
