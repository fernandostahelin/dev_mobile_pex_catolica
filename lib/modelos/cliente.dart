class Cliente {
  final String nome;
  final String email;
  final String telefone;
  final String senha;

  Cliente({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.senha,
  });

  // Método para converter Cliente para Map (útil para armazenamento)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
    };
  }

  // Método para criar Cliente a partir de Map
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      senha: map['senha'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Cliente(nome: $nome, email: $email, telefone: $telefone)';
  }
}
