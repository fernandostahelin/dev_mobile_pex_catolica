import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../modelos/cliente.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Cadastra um novo cliente com Firebase Authentication
  /// Retorna um Map com 'success' (bool) e 'message' (String)
  static Future<Map<String, dynamic>> cadastrarCliente(
    Cliente novoCliente,
  ) async {
    try {
      // Verifica se a senha foi fornecida
      if (novoCliente.senha == null || novoCliente.senha!.isEmpty) {
        return {'success': false, 'message': 'Senha é obrigatória'};
      }

      // Cria o usuário no Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: novoCliente.email,
            password: novoCliente.senha!,
          );

      // Salva informações adicionais no Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nome': novoCliente.nome,
        'email': novoCliente.email,
        'telefone': novoCliente.telefone,
        'dataCadastro': FieldValue.serverTimestamp(),
        'authProvider': 'email',
        'interesseNovosImoveis': false,
        'interesseContato': false,
      });

      return {'success': true, 'message': 'Cliente cadastrado com sucesso!'};
    } on FirebaseAuthException catch (e) {
      debugPrint('Erro ao cadastrar: ${e.code}');

      // Mapeia códigos de erro específicos para mensagens em português
      String mensagem;
      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este email já está cadastrado';
          break;
        case 'invalid-email':
          mensagem = 'Email inválido';
          break;
        case 'operation-not-allowed':
          mensagem =
              'Cadastro com email/senha não está habilitado. Entre em contato com o suporte.';
          break;
        case 'weak-password':
          mensagem = 'A senha é muito fraca';
          break;
        default:
          mensagem = 'Erro ao cadastrar: ${e.message ?? e.code}';
      }

      return {'success': false, 'message': mensagem};
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      return {
        'success': false,
        'message': 'Erro inesperado ao cadastrar. Tente novamente.',
      };
    }
  }

  /// Autentica um cliente com email e senha
  /// Retorna o Cliente se as credenciais estão corretas, null caso contrário
  static Future<Cliente?> autenticarCliente(String email, String senha) async {
    try {
      // Faz login no Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Busca os dados adicionais do Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Cliente(
          nome: data['nome'] ?? '',
          email: data['email'] ?? email,
          telefone: data['telefone'] ?? '',
          senha: senha, // Mantém senha localmente para compatibilidade
          profilePicture: data['profilePicture'],
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Erro ao autenticar: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      return null;
    }
  }

  /// Retorna o cliente atualmente logado
  static Future<Cliente?> get clienteLogado async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Cliente(
          nome: data['nome'] ?? '',
          email: data['email'] ?? user.email ?? '',
          telefone: data['telefone'] ?? '',
          senha: '', // Senha não é armazenada
          profilePicture: data['profilePicture'],
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar cliente: $e');
    }
    return null;
  }

  /// Retorna os dados completos do usuário atual incluindo profilePicture
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  /// Atualiza o perfil do usuário (nome, telefone, profilePicture)
  /// Retorna um Map com 'success' (bool) e 'message' (String)
  static Future<Map<String, dynamic>> updateUserProfile({
    required String nome,
    String? telefone,
    String? profilePicture,
    bool? interesseNovosImoveis,
    bool? interesseContato,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Usuário não autenticado.'};
      }

      // Valida o nome
      if (nome.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Por favor, preencha todos os campos obrigatórios.',
        };
      }

      // Prepara os dados para atualização
      Map<String, dynamic> updateData = {
        'nome': nome.trim(),
        'telefone': telefone?.trim(),
      };

      // Adiciona profilePicture apenas se fornecido
      if (profilePicture != null) {
        updateData['profilePicture'] = profilePicture;
      }

      // Adiciona preferências se fornecidas
      if (interesseNovosImoveis != null) {
        updateData['interesseNovosImoveis'] = interesseNovosImoveis;
      }
      if (interesseContato != null) {
        updateData['interesseContato'] = interesseContato;
      }

      // Atualiza no Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);

      return {'success': true, 'message': 'Perfil atualizado com sucesso!'};
    } on FirebaseException catch (e) {
      debugPrint('Erro Firebase ao atualizar perfil: ${e.code}');
      if (e.code == 'unavailable') {
        return {
          'success': false,
          'message': 'Sem conexão com a internet. Verifique sua conexão.',
        };
      }
      return {
        'success': false,
        'message': 'Erro ao salvar alterações. Tente novamente.',
      };
    } catch (e) {
      debugPrint('Erro inesperado ao atualizar perfil: $e');
      return {
        'success': false,
        'message': 'Erro ao salvar alterações. Tente novamente.',
      };
    }
  }

  /// Verifica se há um cliente logado
  static bool get estaLogado => _auth.currentUser != null;

  /// Retorna o email do usuário atual (para buscar documentos)
  static String? get emailUsuarioAtual => _auth.currentUser?.email;

  /// Faz logout do cliente atual
  static Future<void> fazerLogout() async {
    await _auth.signOut();
  }

  /// Retorna o usuário atual do Firebase
  static User? get usuarioAtual => _auth.currentUser;

  /// Autentica com Google Sign-In
  static Future<Cliente?> signInWithGoogle() async {
    try {
      // Inicia o fluxo de autenticação do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Usuário cancelou o login
        return null;
      }

      // Obtém os detalhes de autenticação do Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Cria uma credencial do Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz login no Firebase com a credencial do Google
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;
      if (user == null) return null;

      // Verifica se é um novo usuário ou já existe
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Cria novo documento para usuário do Google
        await _firestore.collection('users').doc(user.uid).set({
          'nome': user.displayName ?? 'Usuário',
          'email': user.email ?? '',
          'telefone': null,
          'photoUrl': user.photoURL,
          'authProvider': 'google',
          'dataCadastro': FieldValue.serverTimestamp(),
          'interesseNovosImoveis': false,
          'interesseContato': false,
        });
      } else {
        // Atualiza informações se necessário
        await _firestore.collection('users').doc(user.uid).update({
          'nome': user.displayName ?? 'Usuário',
          'photoUrl': user.photoURL,
        });
      }

      // Busca os dados do Firestore para retornar
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Cliente(
          nome: data['nome'] ?? user.displayName ?? '',
          email: data['email'] ?? user.email ?? '',
          telefone: data['telefone'],
          photoUrl: data['photoUrl'] ?? user.photoURL,
          authProvider: data['authProvider'] ?? 'google',
          profilePicture: data['profilePicture'],
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Erro ao autenticar com Google: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Erro inesperado ao autenticar com Google: $e');
      return null;
    }
  }

  /// Faz logout do Google também
  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Verifica se o usuário atual é admin
  static Future<bool> isAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Busca configuração de admins
      DocumentSnapshot configDoc = await _firestore
          .collection('config')
          .doc('admins')
          .get();

      if (!configDoc.exists) return false;

      Map<String, dynamic> data = configDoc.data() as Map<String, dynamic>;
      List<dynamic> adminEmails = data['emails'] ?? [];

      return adminEmails.contains(user.email);
    } catch (e) {
      debugPrint('Erro ao verificar admin: $e');
      return false;
    }
  }

  /// Busca número do WhatsApp da configuração
  static Future<String?> getWhatsAppNumber() async {
    try {
      DocumentSnapshot configDoc = await _firestore
          .collection('config')
          .doc('admins')
          .get();

      if (!configDoc.exists) return null;

      Map<String, dynamic> data = configDoc.data() as Map<String, dynamic>;
      return data['whatsappNumber'];
    } catch (e) {
      debugPrint('Erro ao buscar WhatsApp: $e');
      return null;
    }
  }

  /// Busca todos os usuários cadastrados (apenas para admins)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('nome')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'nome': data['nome'] ?? '',
          'email': data['email'] ?? '',
          'telefone': data['telefone'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar todos os usuários: $e');
      return [];
    }
  }
}
