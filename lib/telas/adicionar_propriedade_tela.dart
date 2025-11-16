import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../modelos/propriedade.dart';
import '../servicos/propriedade_service.dart';

class AdicionarPropriedadeTela extends StatefulWidget {
  final Propriedade? propriedade;

  const AdicionarPropriedadeTela({super.key, this.propriedade});

  @override
  State<AdicionarPropriedadeTela> createState() =>
      _AdicionarPropriedadeTelaState();
}

class _AdicionarPropriedadeTelaState extends State<AdicionarPropriedadeTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _precoController = TextEditingController();

  String _tipo = 'casa';
  String _status = 'disponivel';
  File? _imageFile;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.propriedade != null) {
      _isEditing = true;
      _nomeController.text = widget.propriedade!.nome;
      _localizacaoController.text = widget.propriedade!.localizacao;
      _precoController.text = widget.propriedade!.preco.toStringAsFixed(2);
      _tipo = widget.propriedade!.tipo;
      _status = widget.propriedade!.status;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localizacaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Verifica tamanho do arquivo (máximo 5MB)
        File file = File(image.path);
        int fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagem muito grande. Máximo 5MB.')),
            );
          }
          return;
        }

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEditing && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma imagem')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double preco = double.parse(_precoController.text.replaceAll(',', '.'));

      Propriedade propriedade = Propriedade(
        id: _isEditing ? widget.propriedade!.id : '',
        nome: _nomeController.text.trim(),
        localizacao: _localizacaoController.text.trim(),
        preco: preco,
        imageUrl: _isEditing ? widget.propriedade!.imageUrl : '',
        status: _status,
        tipo: _tipo,
        dataAdicionada: _isEditing
            ? widget.propriedade!.dataAdicionada
            : DateTime.now(),
      );

      bool sucesso;
      if (_isEditing) {
        sucesso = await PropriedadeService.atualizarPropriedade(
          propriedade,
          _imageFile,
        );
      } else {
        sucesso = await PropriedadeService.adicionarPropriedade(
          propriedade,
          _imageFile,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (sucesso) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Propriedade atualizada!'
                    : 'Propriedade adicionada!',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar propriedade')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Propriedade' : 'Adicionar Propriedade',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção de imagem
              Center(
                child: GestureDetector(
                  onTap: _selecionarImagem,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : _isEditing && widget.propriedade!.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.propriedade!.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque para adicionar imagem',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Imóvel',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Localização
              TextFormField(
                controller: _localizacaoController,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Localização é obrigatória';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Preço
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Preço é obrigatório';
                  }
                  try {
                    double.parse(value.replaceAll(',', '.'));
                  } catch (e) {
                    return 'Preço inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Tipo
              const Text(
                'Tipo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Casa'),
                    selected: _tipo == 'casa',
                    onSelected: (selected) {
                      setState(() {
                        _tipo = 'casa';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Apartamento'),
                    selected: _tipo == 'apartamento',
                    onSelected: (selected) {
                      setState(() {
                        _tipo = 'apartamento';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status
              const Text(
                'Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Disponível'),
                    selected: _status == 'disponivel',
                    selectedColor: Colors.green[100],
                    onSelected: (selected) {
                      setState(() {
                        _status = 'disponivel';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Vendido'),
                    selected: _status == 'vendido',
                    selectedColor: Colors.red[100],
                    onSelected: (selected) {
                      setState(() {
                        _status = 'vendido';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Alugado'),
                    selected: _status == 'alugado',
                    selectedColor: Colors.orange[100],
                    onSelected: (selected) {
                      setState(() {
                        _status = 'alugado';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvarPropriedade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(_isEditing ? 'Atualizar' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
