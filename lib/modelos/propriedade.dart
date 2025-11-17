import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Propriedade {
  final String id;
  final String nome;
  final String localizacao;
  final double preco;
  final String imageUrl; // Deprecated - keeping for backward compatibility
  final String? imageBase64; // New field for base64 image storage
  final String status; // 'disponivel', 'vendido', 'alugado'
  final String tipo; // 'casa' or 'apartamento'
  final DateTime dataAdicionada;

  Propriedade({
    required this.id,
    required this.nome,
    required this.localizacao,
    required this.preco,
    required this.imageUrl,
    this.imageBase64,
    required this.status,
    required this.tipo,
    required this.dataAdicionada,
  });

  // Formata o preço em reais
  String get formattedPrice {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(preco);
  }

  // Formata a data de adição
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(dataAdicionada);
  }

  // Retorna o texto do status em português
  String get statusText {
    switch (status) {
      case 'disponivel':
        return 'Disponível';
      case 'vendido':
        return 'Vendido';
      case 'alugado':
        return 'Alugado';
      default:
        return status;
    }
  }

  // Retorna o texto do tipo em português
  String get tipoText {
    switch (tipo) {
      case 'casa':
        return 'Casa';
      case 'apartamento':
        return 'Apartamento';
      default:
        return tipo;
    }
  }

  // Converter para Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'localizacao': localizacao,
      'preco': preco,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'status': status,
      'tipo': tipo,
      'dataAdicionada': Timestamp.fromDate(dataAdicionada),
    };
  }

  // Criar a partir de Map do Firestore
  factory Propriedade.fromMap(String id, Map<String, dynamic> map) {
    return Propriedade(
      id: id,
      nome: map['nome'] ?? '',
      localizacao: map['localizacao'] ?? '',
      preco: (map['preco'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      imageBase64: map['imageBase64'],
      status: map['status'] ?? 'disponivel',
      tipo: map['tipo'] ?? 'casa',
      dataAdicionada:
          (map['dataAdicionada'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Cria uma cópia com valores modificados
  Propriedade copyWith({
    String? id,
    String? nome,
    String? localizacao,
    double? preco,
    String? imageUrl,
    String? imageBase64,
    String? status,
    String? tipo,
    DateTime? dataAdicionada,
  }) {
    return Propriedade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      localizacao: localizacao ?? this.localizacao,
      preco: preco ?? this.preco,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      status: status ?? this.status,
      tipo: tipo ?? this.tipo,
      dataAdicionada: dataAdicionada ?? this.dataAdicionada,
    );
  }

  @override
  String toString() {
    return 'Propriedade(id: $id, nome: $nome, localizacao: $localizacao, preco: $preco)';
  }
}
