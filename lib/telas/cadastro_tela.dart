import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modelos/cliente.dart';
import '../servicos/auth_service.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
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

  // Validação de telefone
  String? _validarTelefone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (!RegExp(r'^\(\d{3}\)\s\d{9}$').hasMatch(value)) {
      return 'Digite no formato (047) 912345678';
    }
    return null;
  }

  // Validação de senha
  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  // Validação de confirmação de senha
  String? _validarConfirmarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != _senhaController.text) {
      return 'Senhas não coincidem';
    }
    return null;
  }

  // Formatação do telefone
  void _formatarTelefone(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length <= 3) {
      _telefoneController.text = digitsOnly;
    } else if (digitsOnly.length <= 6) {
      _telefoneController.text = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else if (digitsOnly.length <= 11) {
      _telefoneController.text = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 7)}${digitsOnly.substring(7)}';
    }
    
    _telefoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _telefoneController.text.length),
    );
  }

  // Método para cadastrar cliente
  Future<void> _cadastrarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simula um delay de rede
    await Future.delayed(const Duration(seconds: 1));

    try {
      Cliente novoCliente = Cliente(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        senha: _senhaController.text,
      );

      bool sucesso = AuthService.cadastrarCliente(novoCliente);

      setState(() {
        _isLoading = false;
      });

      if (sucesso) {
        // Mostra diálogo de sucesso
        _mostrarDialogoSucesso();
      } else {
        // Mostra erro se email já existe
        _mostrarDialogoErro('Este email já está cadastrado');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarDialogoErro('Erro ao cadastrar. Tente novamente.');
    }
  }

  // Diálogo de sucesso
  void _mostrarDialogoSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Sucesso!'),
            ],
          ),
          content: const Text('Cliente cadastrado com sucesso!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/inicio', 
                  (route) => false
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
                      Icons.person_add,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Título
                const Center(
                  child: Text(
                    'Cadastro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Campo Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Insira seu nome',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
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
                
                // Campo Telefone
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: _formatarTelefone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(047) 912345678',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: _validarTelefone,
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
                
                const SizedBox(height: 16),
                
                // Campo Confirme a Senha
                TextFormField(
                  controller: _confirmarSenhaController,
                  obscureText: !_confirmarSenhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Confirme a senha',
                    hintText: 'Confirme a senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                        });
                      },
                    ),
                  ),
                  validator: _validarConfirmarSenha,
                ),
                
                const SizedBox(height: 30),
                
                // Botão Cadastrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cadastrarCliente,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Cadastrar',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
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
