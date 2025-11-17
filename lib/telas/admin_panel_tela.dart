import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../modelos/propriedade.dart';
import '../servicos/propriedade_service.dart';
import '../servicos/auth_service.dart';

class AdminPanelTela extends StatefulWidget {
  const AdminPanelTela({super.key});

  @override
  State<AdminPanelTela> createState() => _AdminPanelTelaState();
}

class _AdminPanelTelaState extends State<AdminPanelTela> {
  List<Propriedade> _propriedades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
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
    _carregarPropriedades();
  }

  Future<void> _carregarPropriedades() async {
    setState(() {
      _isLoading = true;
    });

    List<Propriedade> propriedades = await PropriedadeService.getPropriedades();

    setState(() {
      _propriedades = propriedades;
      _isLoading = false;
    });
  }

  Future<void> _confirmarDelete(Propriedade propriedade) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir "${propriedade.nome}"?'),
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
      _deletarPropriedade(propriedade);
    }
  }

  Future<void> _deletarPropriedade(Propriedade propriedade) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool sucesso = await PropriedadeService.deletarPropriedade(
      propriedade.id,
      propriedade.imageUrl,
    );

    if (mounted) {
      Navigator.pop(context); // Fecha loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriedade excluída com sucesso')),
        );
        _carregarPropriedades();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir propriedade')),
        );
      }
    }
  }

  Widget _buildPropertyImage(
    Propriedade propriedade, {
    double? width,
    double? height,
  }) {
    // Se tem imagem base64, usa ela
    if (propriedade.imageBase64 != null &&
        propriedade.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(propriedade.imageBase64!);
        return Image.memory(
          Uint8List.fromList(bytes),
          width: width ?? 80,
          height: height ?? 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width ?? 80,
              height: height ?? 80,
              color: Colors.grey[300],
              child: const Icon(Icons.home),
            );
          },
        );
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
      }
    }

    // Fallback para URL antiga (compatibilidade)
    if (propriedade.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: propriedade.imageUrl,
        width: width ?? 80,
        height: height ?? 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width ?? 80,
          height: height ?? 80,
          color: Colors.grey[300],
          child: const Icon(Icons.home),
        ),
        errorWidget: (context, url, error) => Container(
          width: width ?? 80,
          height: height ?? 80,
          color: Colors.grey[300],
          child: const Icon(Icons.home),
        ),
      );
    }

    // Sem imagem
    return Container(
      width: width ?? 80,
      height: height ?? 80,
      color: Colors.grey[300],
      child: const Icon(Icons.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: () {
              Navigator.pushNamed(context, '/admin-documentos');
            },
            tooltip: 'Gerenciar Documentos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _propriedades.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma propriedade cadastrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/adicionar-propriedade',
                      );
                      _carregarPropriedades();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Primeira Propriedade'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarPropriedades,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _propriedades.length,
                itemBuilder: (context, index) {
                  Propriedade propriedade = _propriedades[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildPropertyImage(
                          propriedade,
                          width: 80,
                          height: 80,
                        ),
                      ),
                      title: Text(
                        propriedade.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(propriedade.localizacao),
                          const SizedBox(height: 4),
                          Text(
                            propriedade.formattedPrice,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            propriedade.statusText,
                            style: TextStyle(
                              color: _getStatusColor(propriedade.status),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                '/editar-propriedade',
                                arguments: propriedade,
                              );
                              _carregarPropriedades();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarDelete(propriedade),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/adicionar-propriedade');
          _carregarPropriedades();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disponivel':
        return Colors.green;
      case 'vendido':
        return Colors.red;
      case 'alugado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
