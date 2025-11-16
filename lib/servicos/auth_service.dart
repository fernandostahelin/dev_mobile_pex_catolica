import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../modelos/cliente.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Cadastra um novo cliente com Firebase Authentication
  /// Retorna true se o cadastro foi bem-sucedido, false se houve erro
  static Future<bool> cadastrarCliente(Cliente novoCliente) async {
    try {
      // Verifica se a senha foi fornecida
      if (novoCliente.senha == null || novoCliente.senha!.isEmpty) {
        return false;
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
      });

      return true;
    } on FirebaseAuthException catch (e) {
      // Email já existe ou outro erro
      print('Erro ao cadastrar: ${e.code}');
      return false;
    } catch (e) {
      print('Erro inesperado: $e');
      return false;
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
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Erro ao autenticar: ${e.code}');
      return null;
    } catch (e) {
      print('Erro inesperado: $e');
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
        );
      }
    } catch (e) {
      print('Erro ao buscar cliente: $e');
    }
    return null;
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
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('Erro ao autenticar com Google: ${e.code}');
      return null;
    } catch (e) {
      print('Erro inesperado ao autenticar com Google: $e');
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
      DocumentSnapshot configDoc =
          await _firestore.collection('config').doc('admins').get();

      if (!configDoc.exists) return false;

      Map<String, dynamic> data = configDoc.data() as Map<String, dynamic>;
      List<dynamic> adminEmails = data['emails'] ?? [];

      return adminEmails.contains(user.email);
    } catch (e) {
      print('Erro ao verificar admin: $e');
      return false;
    }
  }

  /// Busca número do WhatsApp da configuração
  static Future<String?> getWhatsAppNumber() async {
    try {
      DocumentSnapshot configDoc =
          await _firestore.collection('config').doc('admins').get();

      if (!configDoc.exists) return null;

      Map<String, dynamic> data = configDoc.data() as Map<String, dynamic>;
      return data['whatsappNumber'];
    } catch (e) {
      print('Erro ao buscar WhatsApp: $e');
      return null;
    }
  }
}
