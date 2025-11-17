import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../modelos/propriedade.dart';
import '../servicos/propriedade_service.dart';
import '../servicos/auth_service.dart';

class InicioTela extends StatefulWidget {
  const InicioTela({super.key});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  List<Propriedade> _propriedades = [];
  List<Propriedade> _propriedadesFiltradas = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _searchQuery = '';
  String? _tipoFiltro;
  String? _statusFiltro;
  String? _localizacaoFiltro;
  String _ordenacao = 'recente';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    // Verifica se é admin
    bool isAdmin = await AuthService.isAdmin();

    // Carrega propriedades
    List<Propriedade> propriedades = await PropriedadeService.getPropriedades();

    setState(() {
      _isAdmin = isAdmin;
      _propriedades = propriedades;
      _aplicarFiltros();
      _isLoading = false;
    });
  }

  void _aplicarFiltros() {
    List<Propriedade> filtered = List.from(_propriedades);

    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.localizacao.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtro de tipo
    if (_tipoFiltro != null && _tipoFiltro != 'todos') {
      filtered = filtered.where((p) => p.tipo == _tipoFiltro).toList();
    }

    // Filtro de status
    if (_statusFiltro != null && _statusFiltro != 'todos') {
      filtered = filtered.where((p) => p.status == _statusFiltro).toList();
    }

    // Filtro de localização
    if (_localizacaoFiltro != null && _localizacaoFiltro != 'todos') {
      filtered = filtered
          .where((p) => p.localizacao == _localizacaoFiltro)
          .toList();
    }

    // Ordenação
    if (_ordenacao == 'preco_asc') {
      filtered.sort((a, b) => a.preco.compareTo(b.preco));
    } else if (_ordenacao == 'preco_desc') {
      filtered.sort((a, b) => b.preco.compareTo(a.preco));
    } else {
      filtered.sort((a, b) => b.dataAdicionada.compareTo(a.dataAdicionada));
    }

    setState(() {
      _propriedadesFiltradas = filtered;
    });
  }

  void _mostrarDetalhes(Propriedade propriedade) async {
    String? whatsappNumber = await AuthService.getWhatsAppNumber();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagem
            _buildPropertyImage(
              propriedade,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    propriedade.nome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tipo
                  Row(
                    children: [
                      const Icon(Icons.home, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        propriedade.tipoText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Localização
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          propriedade.localizacao,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Preço
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        propriedade.formattedPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(propriedade.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      propriedade.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botão WhatsApp
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _abrirWhatsApp(propriedade, whatsappNumber),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.chat),
                      label: const Text('Entrar em contato'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Future<void> _abrirWhatsApp(Propriedade propriedade, String? number) async {
    if (number == null || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número do WhatsApp não configurado')),
      );
      return;
    }

    String mensagem =
        '''Olá! Tenho interesse no imóvel:

📍 *${propriedade.nome}*
🏠 ${propriedade.tipoText}
📍 ${propriedade.localizacao}
💰 ${propriedade.formattedPrice}

Gostaria de mais informações.''';

    String url = 'https://wa.me/$number?text=${Uri.encodeComponent(mensagem)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  void _mostrarFiltros() {
    // Local copies of filter values
    String? tipoTemp = _tipoFiltro;
    String? statusTemp = _statusFiltro;
    String ordenacaoTemp = _ordenacao;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tipoFiltro = null;
                          _statusFiltro = null;
                          _localizacaoFiltro = null;
                          _ordenacao = 'recente';
                          _aplicarFiltros();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tipo
                    const Text(
                      'Tipo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChipLocal('Todos', null, tipoTemp, (value) {
                          setModalState(() => tipoTemp = value);
                        }),
                        _buildFilterChipLocal('Casa', 'casa', tipoTemp, (
                          value,
                        ) {
                          setModalState(() => tipoTemp = value);
                        }),
                        _buildFilterChipLocal(
                          'Apartamento',
                          'apartamento',
                          tipoTemp,
                          (value) {
                            setModalState(() => tipoTemp = value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Status
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChipLocal('Todos', null, statusTemp, (
                          value,
                        ) {
                          setModalState(() => statusTemp = value);
                        }),
                        _buildFilterChipLocal(
                          'Disponível',
                          'disponivel',
                          statusTemp,
                          (value) {
                            setModalState(() => statusTemp = value);
                          },
                        ),
                        _buildFilterChipLocal(
                          'Vendido',
                          'vendido',
                          statusTemp,
                          (value) {
                            setModalState(() => statusTemp = value);
                          },
                        ),
                        _buildFilterChipLocal(
                          'Alugado',
                          'alugado',
                          statusTemp,
                          (value) {
                            setModalState(() => statusTemp = value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Ordenação
                    const Text(
                      'Ordenar por',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Mais recente'),
                          selected: ordenacaoTemp == 'recente',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => ordenacaoTemp = 'recente');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Menor preço'),
                          selected: ordenacaoTemp == 'preco_asc',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => ordenacaoTemp = 'preco_asc');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Maior preço'),
                          selected: ordenacaoTemp == 'preco_desc',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => ordenacaoTemp = 'preco_desc');
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _tipoFiltro = tipoTemp;
                          _statusFiltro = statusTemp;
                          _ordenacao = ordenacaoTemp;
                        });
                        _aplicarFiltros();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar Filtros'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipLocal(
    String label,
    String? value,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    bool isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onChanged(selected ? value : null);
      },
    );
  }

  Widget _buildPropertyImage(
    Propriedade propriedade, {
    double? height,
    double? width,
    BoxFit? fit,
  }) {
    // Se tem imagem base64, usa ela
    if (propriedade.imageBase64 != null &&
        propriedade.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(propriedade.imageBase64!);
        return Image.memory(
          Uint8List.fromList(bytes),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              width: width,
              color: Colors.grey[300],
              child: const Icon(Icons.home, size: 40, color: Colors.grey),
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
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          child: const Icon(Icons.home, size: 40, color: Colors.grey),
        ),
      );
    }

    // Sem imagem
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: const Icon(Icons.home, size: 40, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar e filtro
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar imóveis...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _mostrarFiltros,
                    icon: const Icon(Icons.tune),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de propriedades
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _propriedadesFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum imóvel encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarDados,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _propriedadesFiltradas.length,
                        itemBuilder: (context, index) {
                          Propriedade propriedade =
                              _propriedadesFiltradas[index];
                          return _buildPropertyCard(propriedade);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/admin-panel',
                ).then((_) => _carregarDados());
              },
              child: const Icon(Icons.business),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Área do Cliente',
          ),
        ],
        onTap: (index) async {
          if (index == 1) {
            // Verifica se o usuário está logado
            bool estaLogado = AuthService.estaLogado;
            if (estaLogado) {
              Navigator.pushNamed(context, '/area-cliente-logado');
            } else {
              Navigator.pushNamed(context, '/area-cliente-sem-login');
            }
          }
        },
      ),
    );
  }

  Widget _buildPropertyCard(Propriedade propriedade) {
    return GestureDetector(
      onTap: () => _mostrarDetalhes(propriedade),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPropertyImage(propriedade, fit: BoxFit.cover),
                  // Badge de status
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(propriedade.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        propriedade.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informações
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propriedade.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          propriedade.localizacao,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    propriedade.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
