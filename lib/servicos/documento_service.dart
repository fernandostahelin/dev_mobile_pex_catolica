import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../modelos/documento.dart';

class DocumentoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca todos os documentos de um cliente específico por email
  static Future<List<Documento>> getDocumentosPorCliente(
    String clientEmail,
  ) async {
    try {
      debugPrint('Buscando documentos para: $clientEmail');

      QuerySnapshot snapshot = await _firestore
          .collection('documentos')
          .where('clientEmail', isEqualTo: clientEmail)
          .get();

      debugPrint('Snapshot recebido com ${snapshot.docs.length} documentos');

      List<Documento> documentos = snapshot.docs
          .map(
            (doc) =>
                Documento.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Ordena localmente por data de upload (mais recente primeiro)
      documentos.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

      return documentos;
    } catch (e) {
      debugPrint('Erro ao buscar documentos: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Converte URL do Google Drive para URL de download direto
  static String _convertGoogleDriveUrl(String url) {
    // Se já for URL de download, retorna como está
    if (url.contains('uc?export=download')) {
      return url;
    }

    // Extrai o ID do arquivo de URLs do Google Drive
    RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    Match? match = regExp.firstMatch(url);

    if (match != null) {
      String fileId = match.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // Se não for Google Drive, retorna a URL original
    return url;
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

      // Converter URL do Google Drive se necessário
      String downloadUrl = _convertGoogleDriveUrl(documento.downloadUrl);

      // Baixar o arquivo
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        debugPrint('Erro ao baixar: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao baixar documento: $e');
      return null;
    }
  }

  /// Adiciona um documento ao Firestore com Google Drive URL
  /// Use este método via Firebase Console ou crie um admin screen
  static Future<bool> adicionarDocumento({
    required String fileName,
    required String
    googleDriveUrl, // URL do Google Drive (pode ser link de compartilhamento ou download direto)
    required String clientEmail,
    required int fileSize,
  }) async {
    try {
      // Converte para URL de download direto se necessário
      String downloadUrl = _convertGoogleDriveUrl(googleDriveUrl);

      await _firestore.collection('documentos').add({
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadDate': FieldValue.serverTimestamp(),
        'clientEmail': clientEmail,
        'fileSize': fileSize,
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao adicionar documento: $e');
      return false;
    }
  }

  /// Deleta um documento do Firestore (não deleta do Google Drive)
  static Future<bool> deletarDocumento(String documentoId) async {
    try {
      await _firestore.collection('documentos').doc(documentoId).delete();
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar documento: $e');
      return false;
    }
  }
}
