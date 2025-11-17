// Este arquivo contém exemplos de como usar o error handling no seu código
// NÃO é necessário usar este arquivo, é apenas para referência

import 'package:flutter/material.dart';
import 'erro_widget.dart';

/// EXEMPLO 1: Usando try-catch em uma função assíncrona
///
/// Você pode usar o ErroBox para exibir erros específicos em uma parte da tela
class ExemploTryCatch extends StatefulWidget {
  const ExemploTryCatch({super.key});

  @override
  State<ExemploTryCatch> createState() => _ExemploTryCatchState();
}

class _ExemploTryCatchState extends State<ExemploTryCatch> {
  bool _carregando = false;
  Object? _erro;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Seu código que pode gerar erro
      // Por exemplo: await FirebaseFirestore.instance.collection('...').get();

      setState(() {
        _carregando = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _carregando = false;
        _erro = e;
        _stackTrace = stackTrace;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return ErroBox(
        error: _erro!,
        stackTrace: _stackTrace,
        mensagem: 'Não foi possível carregar os dados',
      );
    }

    return const Text('Dados carregados com sucesso!');
  }
}

/// EXEMPLO 2: Usando FutureBuilder com tratamento de erro
///
/// O FutureBuilder já lida com erros automaticamente
class ExemploFutureBuilder extends StatelessWidget {
  const ExemploFutureBuilder({super.key});

  Future<String> _buscarDados() async {
    // Simula uma chamada assíncrona que pode falhar
    await Future.delayed(const Duration(seconds: 2));
    throw Exception('Erro ao buscar dados');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _buscarDados(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErroBox(
            error: snapshot.error!,
            stackTrace: snapshot.stackTrace,
            mensagem: 'Não foi possível buscar os dados',
          );
        }

        return Text('Dados: ${snapshot.data}');
      },
    );
  }
}

/// EXEMPLO 3: Usando em um botão com ação
///
/// Quando uma ação pode falhar, mostre o erro em um dialog
class ExemploAcaoComErro extends StatelessWidget {
  const ExemploAcaoComErro({super.key});

  Future<void> _executarAcao(BuildContext context) async {
    try {
      // Sua ação que pode falhar
      // Por exemplo: await FirebaseAuth.instance.signInWithEmailAndPassword(...);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ação executada com sucesso!')),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ErroBox(
              error: e,
              stackTrace: stackTrace,
              mensagem: 'Não foi possível executar a ação',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _executarAcao(context),
      child: const Text('Executar Ação'),
    );
  }
}
