import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ErroService {
  static const String emailDestino = 'fernandostahelin@gmail.com';

  /// Reporta um erro enviando um email com os detalhes
  static Future<void> reportarErro(
    Object erro,
    StackTrace? stackTrace,
  ) async {
    try {
      // Coleta informações do dispositivo
      final deviceInfo = await _getDeviceInfo();
      
      // Constrói o corpo do email
      final String assunto = Uri.encodeComponent('Erro no App PEX');
      final String corpo = Uri.encodeComponent(_construirCorpoEmail(
        erro,
        stackTrace,
        deviceInfo,
      ));

      // Constrói a URL do mailto
      final Uri emailUri = Uri.parse(
        'mailto:$emailDestino?subject=$assunto&body=$corpo',
      );

      // Tenta abrir o cliente de email
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Se não conseguir abrir o cliente de email, tenta copiar para a área de transferência
        if (kDebugMode) {
          print('Não foi possível abrir o cliente de email');
          print('Erro: $erro');
          print('StackTrace: $stackTrace');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao reportar erro: $e');
      }
    }
  }

  /// Obtém informações do dispositivo
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final Map<String, String> info = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['Platform'] = 'Android';
        info['Versão'] = androidInfo.version.release;
        info['SDK'] = androidInfo.version.sdkInt.toString();
        info['Modelo'] = androidInfo.model;
        info['Marca'] = androidInfo.brand;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['Platform'] = 'iOS';
        info['Versão'] = iosInfo.systemVersion;
        info['Modelo'] = iosInfo.model;
        info['Nome'] = iosInfo.name;
      } else {
        info['Platform'] = Platform.operatingSystem;
        info['Versão'] = Platform.operatingSystemVersion;
      }
    } catch (e) {
      info['Platform'] = 'Desconhecida';
      if (kDebugMode) {
        print('Erro ao obter informações do dispositivo: $e');
      }
    }

    return info;
  }

  /// Constrói o corpo do email com as informações do erro
  static String _construirCorpoEmail(
    Object erro,
    StackTrace? stackTrace,
    Map<String, String> deviceInfo,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('RELATÓRIO DE ERRO - APP PEX');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Informações do dispositivo
    buffer.writeln('INFORMAÇÕES DO DISPOSITIVO:');
    deviceInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    buffer.writeln();

    // Data e hora
    buffer.writeln('Data e Hora: ${DateTime.now().toLocal()}');
    buffer.writeln();

    // Informações do erro
    buffer.writeln('ERRO:');
    buffer.writeln(erro.toString());
    buffer.writeln();

    // Stack trace
    if (stackTrace != null) {
      buffer.writeln('STACK TRACE:');
      buffer.writeln(stackTrace.toString());
    }

    return buffer.toString();
  }

  /// Log de erro no console (apenas em modo debug)
  static void logErro(Object erro, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('ERRO: $erro');
      if (stackTrace != null) {
        print('STACK TRACE: $stackTrace');
      }
    }
  }
}

