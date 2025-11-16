import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
          .map((doc) => Propriedade.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar propriedades: $e');
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
          .map((doc) => Propriedade.fromMap(doc.id, doc.data() as Map<String, dynamic>))
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
      print('Erro ao buscar propriedades com filtros: $e');
      return [];
    }
  }

  /// Busca localizações únicas
  static Future<List<String>> getLocalizacoesUnicas() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('propriedades').get();

      Set<String> localizacoes = {};
      for (var doc in snapshot.docs) {
        String loc = (doc.data() as Map<String, dynamic>)['localizacao'] ?? '';
        if (loc.isNotEmpty) {
          localizacoes.add(loc);
        }
      }

      return localizacoes.toList()..sort();
    } catch (e) {
      print('Erro ao buscar localizações: $e');
      return [];
    }
  }

  /// Comprime e faz upload de imagem
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
        print('Erro ao comprimir imagem');
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
        print('Erro ao deletar arquivo temporário: $e');
      }

      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Adiciona nova propriedade
  static Future<bool> adicionarPropriedade(
    Propriedade propriedade,
    File? imageFile,
  ) async {
    try {
      // Cria documento no Firestore para obter ID
      DocumentReference docRef =
          await _firestore.collection('propriedades').add(propriedade.toMap());

      // Se tem imagem, faz upload
      if (imageFile != null) {
        String? imageUrl = await uploadImagem(imageFile, docRef.id);
        if (imageUrl != null) {
          await docRef.update({'imageUrl': imageUrl});
        }
      }

      return true;
    } catch (e) {
      print('Erro ao adicionar propriedade: $e');
      return false;
    }
  }

  /// Atualiza propriedade existente
  static Future<bool> atualizarPropriedade(
    Propriedade propriedade,
    File? newImageFile,
  ) async {
    try {
      Map<String, dynamic> data = propriedade.toMap();

      // Se tem nova imagem
      if (newImageFile != null) {
        // Deleta imagem antiga se existir
        if (propriedade.imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(propriedade.imageUrl).delete();
          } catch (e) {
            print('Erro ao deletar imagem antiga: $e');
          }
        }

        // Upload nova imagem
        String? imageUrl = await uploadImagem(newImageFile, propriedade.id);
        if (imageUrl != null) {
          data['imageUrl'] = imageUrl;
        }
      }

      await _firestore.collection('propriedades').doc(propriedade.id).update(data);
      return true;
    } catch (e) {
      print('Erro ao atualizar propriedade: $e');
      return false;
    }
  }

  /// Deleta propriedade
  static Future<bool> deletarPropriedade(String id, String imageUrl) async {
    try {
      // Deleta imagem do Storage
      if (imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Erro ao deletar imagem: $e');
        }
      }

      // Deleta documento do Firestore
      await _firestore.collection('propriedades').doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar propriedade: $e');
      return false;
    }
  }
}

