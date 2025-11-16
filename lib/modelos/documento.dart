import 'package:cloud_firestore/cloud_firestore.dart';

class Documento {
  final String id;
  final String fileName;
  final String downloadUrl;
  final DateTime uploadDate;
  final String clientEmail;
  final int fileSize;

  Documento({
    required this.id,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadDate,
    required this.clientEmail,
    required this.fileSize,
  });

  // Converter para Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'clientEmail': clientEmail,
      'fileSize': fileSize,
    };
  }

  // Criar a partir de Map do Firestore
  factory Documento.fromMap(String id, Map<String, dynamic> map) {
    return Documento(
      id: id,
      fileName: map['fileName'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
      clientEmail: map['clientEmail'] ?? '',
      fileSize: map['fileSize'] ?? 0,
    );
  }

  // Formatar tamanho do arquivo
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'Documento(id: $id, fileName: $fileName, clientEmail: $clientEmail)';
  }
}
