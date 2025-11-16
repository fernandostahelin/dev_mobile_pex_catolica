import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../modelos/documento.dart';

class DocumentoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Busca todos os documentos de um cliente específico por email
  static Future<List<Documento>> getDocumentosPorCliente(
    String clientEmail,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('documentos')
          .where('clientEmail', isEqualTo: clientEmail)
          .orderBy('uploadDate', descending: true)
          .get();

      List<Documento> documentos = snapshot.docs
          .map(
            (doc) =>
                Documento.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      return documentos;
    } catch (e) {
      print('Erro ao buscar documentos: $e');
      return [];
    }
  }

  /// Baixa um documento e retorna o caminho do arquivo local
  static Future<String?> downloadDocumento(Documento documento) async {
    try {
      // Obter diretório temporário
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/${documento.fileName}';

      // Verificar se o arquivo já existe
      File file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      // Baixar o arquivo
      final response = await http.get(Uri.parse(documento.downloadUrl));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        print('Erro ao baixar: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao baixar documento: $e');
      return null;
    }
  }

  /// Obtém a URL de download de um arquivo no Storage
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      String downloadUrl = await _storage.ref(storagePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao obter URL de download: $e');
      return null;
    }
  }

  /// Adiciona um documento ao Firestore (útil para testes/admin)
  static Future<bool> adicionarDocumento({
    required String fileName,
    required String downloadUrl,
    required String clientEmail,
    required int fileSize,
  }) async {
    try {
      await _firestore.collection('documentos').add({
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadDate': FieldValue.serverTimestamp(),
        'clientEmail': clientEmail,
        'fileSize': fileSize,
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar documento: $e');
      return false;
    }
  }

  /// Deleta um documento (admin only)
  static Future<bool> deletarDocumento(String documentoId) async {
    try {
      await _firestore.collection('documentos').doc(documentoId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar documento: $e');
      return false;
    }
  }
}
