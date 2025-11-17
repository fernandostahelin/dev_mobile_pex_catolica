import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modelos/documento.dart';
import '../servicos/documento_service.dart';
import '../servicos/auth_service.dart';

class AdminDocumentosTela extends StatefulWidget {
  const AdminDocumentosTela({super.key});

  @override
  State<AdminDocumentosTela> createState() => _AdminDocumentosTelaState();
}

class _AdminDocumentosTelaState extends State<AdminDocumentosTela> {
  List<Documento> _documentos = [];
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String? _selectedUserEmail;
  String? _filterUserEmail;
  bool _isFormComplete = false;
  TipoDocumento _selectedFileType = TipoDocumento.pdf;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fileNameController = TextEditingController();
  final _googleDriveUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
    _fileNameController.addListener(_checkFormComplete);
    _googleDriveUrlController.addListener(_checkFormComplete);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _googleDriveUrlController.dispose();
    super.dispose();
  }

  void _checkFormComplete() {
    final isComplete =
        _selectedUserEmail != null &&
        _fileNameController.text.trim().isNotEmpty &&
        _googleDriveUrlController.text.trim().isNotEmpty;

    setState(() {
      _isFormComplete = isComplete;
    });
  }

  Future<void> _verificarAdmin() async {
    bool isAdmin = await AuthService.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/inicio');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acesso negado. Apenas administradores.'),
          ),
        );
      }
      return;
    }
    await _carregarDados();
  }

  Future<void> _carregarDados() async {
    await Future.wait([_carregarUsuarios(), _carregarDocumentos()]);
  }

  Future<void> _carregarUsuarios() async {
    List<Map<String, dynamic>> usuarios = await AuthService.getAllUsers();

    setState(() {
      _usuarios = usuarios;
    });
  }

  Future<void> _carregarDocumentos() async {
    setState(() {
      _isLoading = true;
    });

    List<Documento> documentos = await DocumentoService.getAllDocumentos();

    setState(() {
      _documentos = documentos;
      _isLoading = false;
    });
  }

  List<Documento> get _documentosFiltrados {
    if (_filterUserEmail == null || _filterUserEmail!.isEmpty) {
      return _documentos;
    }
    return _documentos
        .where((doc) => doc.clientEmail == _filterUserEmail)
        .toList();
  }

  Future<void> _adicionarDocumento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserEmail == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um usuário')));
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool sucesso = await DocumentoService.adicionarDocumento(
      fileName: _fileNameController.text.trim(),
      googleDriveUrl: _googleDriveUrlController.text.trim(),
      clientEmail: _selectedUserEmail!,
      fileSize: 0, // Default file size
      fileType: _selectedFileType,
    );

    if (mounted) {
      Navigator.pop(context); // Fecha loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento adicionado com sucesso')),
        );
        _limparFormulario();
        await _carregarDocumentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao adicionar documento')),
        );
      }
    }
  }

  void _limparFormulario() {
    _fileNameController.clear();
    _googleDriveUrlController.clear();
    setState(() {
      _selectedUserEmail = null;
      _selectedFileType = TipoDocumento.pdf;
      _isFormComplete = false;
    });
  }

  Future<void> _confirmarDelete(Documento documento) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir "${documento.fileName}"?\n\nUsuário: ${documento.clientEmail}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _deletarDocumento(documento);
    }
  }

  Future<void> _deletarDocumento(Documento documento) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool sucesso = await DocumentoService.deletarDocumento(documento.id);

    if (mounted) {
      Navigator.pop(context); // Fecha loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento excluído com sucesso')),
        );
        await _carregarDocumentos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir documento')),
        );
      }
    }
  }

  void _mostrarFormularioAdicionar() {
    // Pre-select user if filter is active
    if (_filterUserEmail != null && _selectedUserEmail == null) {
      setState(() {
        _selectedUserEmail = _filterUserEmail;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Adicionar Documento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUserEmail,
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Usuário',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      isExpanded: true,
                      items: _usuarios.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['email'],
                          child: Text(
                            '${user['nome']} (${user['email']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserEmail = value;
                        });
                        _checkFormComplete();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione um usuário';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoDocumento>(
                      value: _selectedFileType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Arquivo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: TipoDocumento.values.map((tipo) {
                        return DropdownMenuItem<TipoDocumento>(
                          value: tipo,
                          child: Row(
                            children: [
                              Icon(
                                tipo == TipoDocumento.pdf
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                size: 20,
                                color: tipo == TipoDocumento.pdf
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(tipo.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFileType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fileNameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Arquivo',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.drive_file_rename_outline),
                        hintText: _selectedFileType == TipoDocumento.pdf
                            ? 'Ex: Contrato.pdf'
                            : 'Ex: Foto_Propriedade.jpg',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o nome do arquivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _googleDriveUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL do Google Drive',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://drive.google.com/...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite a URL do Google Drive';
                        }
                        if (!value.contains('drive.google.com')) {
                          return 'URL inválida do Google Drive';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _adicionarDocumento();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Adicionar Documento'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isFormComplete ? Colors.green : null,
                        foregroundColor: _isFormComplete ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _limparFormulario();
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Documentos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de usuário
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: DropdownButtonFormField<String>(
              initialValue: _filterUserEmail,
              decoration: const InputDecoration(
                labelText: 'Filtrar por Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_alt),
                filled: true,
                fillColor: Colors.white,
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos os usuários'),
                ),
                ..._usuarios.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['email'],
                    child: Text(
                      '${user['nome']} (${user['email']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filterUserEmail = value;
                });
              },
            ),
          ),
          // Lista de documentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documentosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterUserEmail == null
                              ? 'Nenhum documento cadastrado'
                              : 'Nenhum documento para este usuário',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _mostrarFormularioAdicionar,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Documento'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _carregarDocumentos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documentosFiltrados.length,
                      itemBuilder: (context, index) {
                        Documento doc = _documentosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
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
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                            doc.clientEmail,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _confirmarDelete(doc),
                                      tooltip: 'Excluir',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatarData(doc.uploadDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.storage,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc.formattedSize,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioAdicionar,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}
