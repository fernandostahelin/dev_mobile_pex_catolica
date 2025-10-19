import '../modelos/cliente.dart';

class AuthService {
  // Lista para armazenar clientes cadastrados (em memória)
  static final List<Cliente> _clientesCadastrados = [];
  
  // Cliente atualmente logado
  static Cliente? _clienteLogado;

  /// Cadastra um novo cliente
  /// Retorna true se o cadastro foi bem-sucedido, false se o email já existe
  static bool cadastrarCliente(Cliente novoCliente) {
    // Verifica se já existe um cliente com este email
    bool emailJaExiste = _clientesCadastrados.any(
      (cliente) => cliente.email.toLowerCase() == novoCliente.email.toLowerCase()
    );
    
    if (emailJaExiste) {
      return false; // Email já cadastrado
    }
    
    // Adiciona o novo cliente à lista
    _clientesCadastrados.add(novoCliente);
    return true; // Cadastro realizado com sucesso
  }

  /// Autentica um cliente com email e senha
  /// Retorna o Cliente se as credenciais estão corretas, null caso contrário
  static Cliente? autenticarCliente(String email, String senha) {
    try {
      Cliente cliente = _clientesCadastrados.firstWhere(
        (cliente) => 
          cliente.email.toLowerCase() == email.toLowerCase() && 
          cliente.senha == senha
      );
      
      _clienteLogado = cliente;
      return cliente;
    } catch (e) {
      return null; // Credenciais inválidas
    }
  }

  /// Retorna o cliente atualmente logado
  static Cliente? get clienteLogado => _clienteLogado;

  /// Verifica se há um cliente logado
  static bool get estaLogado => _clienteLogado != null;

  /// Faz logout do cliente atual
  static void fazerLogout() {
    _clienteLogado = null;
  }

  /// Retorna a lista de todos os clientes cadastrados (para debug)
  static List<Cliente> get todosClientes => List.from(_clientesCadastrados);

  /// Retorna o número total de clientes cadastrados
  static int get totalClientes => _clientesCadastrados.length;
}
