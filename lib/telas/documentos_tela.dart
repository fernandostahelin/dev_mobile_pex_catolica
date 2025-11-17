import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../modelos/documento.dart';
import '../servicos/documento_service.dart';
import '../servicos/auth_service.dart';

class DocumentosTela extends StatefulWidget {
  const DocumentosTela({super.key});

  @override
  State<DocumentosTela> createState() => _DocumentosTelaState();
}

class _DocumentosTelaState extends State<DocumentosTela> {
  List<Documento> _documentos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? email = AuthService.emailUsuarioAtual;

      if (email == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Buscando documentos para o email: $email');

      List<Documento> documentos =
          await DocumentoService.getDocumentosPorCliente(email);

      debugPrint('Documentos encontrados: ${documentos.length}');

      setState(() {
        _documentos = documentos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar documentos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirDocumento(Documento documento) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Baixar o documento
      String? filePath = await DocumentoService.downloadDocumento(documento);

      // Fechar loading
      if (mounted) Navigator.pop(context);

      if (filePath != null) {
        // Abrir o arquivo com o visualizador padrão usando OpenFilex
        // Especifica o tipo MIME baseado no tipo do documento
        final result = await OpenFilex.open(
          filePath,
          type: documento.fileType.mimeType,
        );

        // Verifica se houve erro ao abrir
        if (result.type != ResultType.done) {
          if (mounted) {
            _mostrarErro(
              'Não foi possível abrir o ${documento.fileType.displayName.toLowerCase()}: ${result.message}',
            );
          }
        }
      } else {
        if (mounted) {
          _mostrarErro(
            'Erro ao baixar o ${documento.fileType.displayName.toLowerCase()}',
          );
        }
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) Navigator.pop(context);
      _mostrarErro(
        'Erro ao abrir ${documento.fileType.displayName.toLowerCase()}: $e',
      );
    }
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Documentos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _carregarDocumentos,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _documentos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum documento disponível',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarDocumentos,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _documentos.length,
                        itemBuilder: (context, index) {
                          Documento doc = _documentos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _abrirDocumento(doc),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: doc.fileType == TipoDocumento.pdf
                                            ? Colors.red.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        doc.fileType == TipoDocumento.pdf
                                            ? Icons.picture_as_pdf
                                            : Icons.image,
                                        color: doc.fileType == TipoDocumento.pdf
                                            ? Colors.red.shade700
                                            : Colors.blue.shade700,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.fileName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatarData(doc.uploadDate)} • ${doc.formattedSize}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Área do Cliente',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/inicio');
          }
          // index == 1 não faz nada, pois já estamos na Área do Cliente
        },
      ),
    );
  }
}
