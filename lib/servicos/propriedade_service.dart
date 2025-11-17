import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import '../modelos/propriedade.dart';

class PropriedadeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Busca todas as propriedades
  static Future<List<Propriedade>> getPropriedades() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('propriedades')
          .orderBy('dataAdicionada', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                Propriedade.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar propriedades: $e');
      return [];
    }
  }

  /// Busca propriedades com filtros e ordenação
  static Future<List<Propriedade>> getPropriedadesComFiltros({
    String? searchQuery,
    double? precoMin,
    double? precoMax,
    String? localizacao,
    String? tipo,
    String? status,
    String? orderBy,
  }) async {
    try {
      Query query = _firestore.collection('propriedades');

      // Aplicar filtros
      if (tipo != null && tipo != 'todos') {
        query = query.where('tipo', isEqualTo: tipo);
      }
      if (status != null && status != 'todos') {
        query = query.where('status', isEqualTo: status);
      }
      if (localizacao != null && localizacao != 'todos') {
        query = query.where('localizacao', isEqualTo: localizacao);
      }

      // Ordenação
      if (orderBy == 'preco_asc') {
        query = query.orderBy('preco', descending: false);
      } else if (orderBy == 'preco_desc') {
        query = query.orderBy('preco', descending: true);
      } else {
        query = query.orderBy('dataAdicionada', descending: true);
      }

      QuerySnapshot snapshot = await query.get();
      List<Propriedade> propriedades = snapshot.docs
          .map(
            (doc) =>
                Propriedade.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Filtro de preço (aplicado localmente)
      if (precoMin != null) {
        propriedades = propriedades.where((p) => p.preco >= precoMin).toList();
      }
      if (precoMax != null) {
        propriedades = propriedades.where((p) => p.preco <= precoMax).toList();
      }

      // Busca por texto (aplicado localmente)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        searchQuery = searchQuery.toLowerCase();
        propriedades = propriedades.where((p) {
          return p.nome.toLowerCase().contains(searchQuery!) ||
              p.localizacao.toLowerCase().contains(searchQuery);
        }).toList();
      }

      return propriedades;
    } catch (e) {
      debugPrint('Erro ao buscar propriedades com filtros: $e');
      return [];
    }
  }

  /// Busca localizações únicas
  static Future<List<String>> getLocalizacoesUnicas() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('propriedades')
          .get();

      Set<String> localizacoes = {};
      for (var doc in snapshot.docs) {
        String loc = (doc.data() as Map<String, dynamic>)['localizacao'] ?? '';
        if (loc.isNotEmpty) {
          localizacoes.add(loc);
        }
      }

      return localizacoes.toList()..sort();
    } catch (e) {
      debugPrint('Erro ao buscar localizações: $e');
      return [];
    }
  }

  /// Comprime e converte imagem para base64
  static Future<String?> compressAndConvertToBase64(File imageFile) async {
    try {
      // Lê os bytes da imagem
      final bytes = await imageFile.readAsBytes();

      // Comprime e redimensiona a imagem
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      // Converte para base64
      final base64String = base64Encode(compressedBytes);

      return base64String;
    } catch (e) {
      debugPrint('Erro ao comprimir e converter imagem: $e');
      return null;
    }
  }

  /// Deprecated - kept for backward compatibility
  static Future<String?> uploadImagem(File imageFile, String propertyId) async {
    try {
      // Comprime a imagem
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.parent.path}/compressed_${imageFile.path.split('/').last}',
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (compressedFile == null) {
        debugPrint('Erro ao comprimir imagem');
        return null;
      }

      // Upload para Firebase Storage
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String path = 'propriedades/$propertyId/$timestamp.jpg';

      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(File(compressedFile.path));

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Deleta arquivo comprimido temporário
      try {
        await File(compressedFile.path).delete();
      } catch (e) {
        debugPrint('Erro ao deletar arquivo temporário: $e');
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Adiciona nova propriedade
  static Future<bool> adicionarPropriedade(
    Propriedade propriedade,
    File? imageFile,
  ) async {
    try {
      // Se tem imagem, converte para base64
      String? imageBase64;
      if (imageFile != null) {
        imageBase64 = await compressAndConvertToBase64(imageFile);
        if (imageBase64 == null) {
          debugPrint('Erro ao processar imagem');
          return false;
        }
      }

      // Cria propriedade com imagem base64
      final propriedadeComImagem = propriedade.copyWith(
        imageBase64: imageBase64,
        imageUrl: '', // Deixa vazio, não usamos mais Firebase Storage
      );

      // Adiciona ao Firestore
      await _firestore
          .collection('propriedades')
          .add(propriedadeComImagem.toMap());

      return true;
    } catch (e) {
      debugPrint('Erro ao adicionar propriedade: $e');
      return false;
    }
  }

  /// Atualiza propriedade existente
  static Future<bool> atualizarPropriedade(
    Propriedade propriedade,
    File? newImageFile,
  ) async {
    try {
      Propriedade propriedadeAtualizada = propriedade;

      // Se tem nova imagem, converte para base64
      if (newImageFile != null) {
        String? imageBase64 = await compressAndConvertToBase64(newImageFile);
        if (imageBase64 != null) {
          propriedadeAtualizada = propriedade.copyWith(
            imageBase64: imageBase64,
            imageUrl: '', // Limpa a URL antiga
          );
        }
      }

      await _firestore
          .collection('propriedades')
          .doc(propriedade.id)
          .update(propriedadeAtualizada.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar propriedade: $e');
      return false;
    }
  }

  /// Deleta propriedade
  static Future<bool> deletarPropriedade(String id, String imageUrl) async {
    try {
      // Se a propriedade antiga usa Firebase Storage, tenta deletar a imagem
      if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('Erro ao deletar imagem do storage (ignorado): $e');
        }
      }

      // Deleta documento do Firestore (imagens base64 são deletadas automaticamente)
      await _firestore.collection('propriedades').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar propriedade: $e');
      return false;
    }
  }
}
