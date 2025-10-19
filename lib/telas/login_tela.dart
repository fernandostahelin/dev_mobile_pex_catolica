import 'package:flutter/material.dart';
import '../servicos/auth_service.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Validação de email
  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Digite um email válido';
    }
    return null;
  }

  // Validação de senha
  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    return null;
  }

  // Método para fazer login
  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simula um delay de rede
    await Future.delayed(const Duration(seconds: 1));

    try {
      var cliente = AuthService.autenticarCliente(
        _emailController.text.trim(),
        _senhaController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (cliente != null) {
        // Login bem-sucedido
        _mostrarDialogoSucesso(cliente.nome);
      } else {
        // Credenciais inválidas
        _mostrarDialogoErro('Email ou senha incorretos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarDialogoErro('Erro ao fazer login. Tente novamente.');
    }
  }

  // Diálogo de sucesso
  void _mostrarDialogoSucesso(String nomeCliente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Login realizado!'),
            ],
          ),
          content: Text('Bem-vindo, $nomeCliente!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/inicio',
                  (route) => false,
                ); // Navega para início
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de erro
  void _mostrarDialogoErro(String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Erro'),
            ],
          ),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder da imagem
                Center(
                  child: Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.login,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Título
                const Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Insira seu email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validarEmail,
                ),

                const SizedBox(height: 16),

                // Campo Senha
                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaVisivel = !_senhaVisivel;
                        });
                      },
                    ),
                  ),
                  validator: _validarSenha,
                ),

                const SizedBox(height: 30),

                // Botão Login
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Área do Cliente',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/inicio');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/area-cliente-sem-login');
          }
        },
      ),
    );
  }
}
