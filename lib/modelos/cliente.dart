class Cliente {
  final String nome;
  final String email;
  final String? telefone;
  final String? senha;
  final String? photoUrl;
  final String? authProvider;

  Cliente({
    required this.nome,
    required this.email,
    this.telefone,
    this.senha,
    this.photoUrl,
    this.authProvider,
  });

  // Método para converter Cliente para Map (útil para armazenamento)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
    };
  }

  // Método para criar Cliente a partir de Map
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'],
      senha: map['senha'],
      photoUrl: map['photoUrl'],
      authProvider: map['authProvider'] ?? 'email',
    );
  }

  @override
  String toString() {
    return 'Cliente(nome: $nome, email: $email, telefone: $telefone)';
  }
}
