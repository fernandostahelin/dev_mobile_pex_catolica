import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../servicos/auth_service.dart';

class InformacoesTela extends StatefulWidget {
  const InformacoesTela({super.key});

  @override
  State<InformacoesTela> createState() => _InformacoesTelasState();
}

class _InformacoesTelasState extends State<InformacoesTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();

  String? _profilePictureBase64;
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  bool _interesseNovosImoveis = false;
  bool _interesseContato = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userData = await AuthService.getCurrentUserData();

      if (userData != null) {
        setState(() {
          _nomeController.text = userData['nome'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _telefoneController.text = userData['telefone'] ?? '';
          _profilePictureBase64 = userData['profilePicture'];
          _interesseNovosImoveis = userData['interesseNovosImoveis'] ?? false;
          _interesseContato = userData['interesseContato'] ?? false;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          _showErrorSnackBar('Erro ao carregar dados do usuário.');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados. Tente novamente.');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showImageSourceBottomSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolher foto de perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profilePictureBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _compressAndConvertImage(pickedFile);
      }
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        _showErrorSnackBar('Permissão de acesso à câmera/galeria negada.');
      } else {
        _showErrorSnackBar('Erro ao processar imagem. Tente novamente.');
      }
    }
  }

  Future<void> _compressAndConvertImage(XFile imageFile) async {
    try {
      setState(() => _isSaving = true);

      // Lê os bytes da imagem
      final bytes = await imageFile.readAsBytes();

      // Comprime e redimensiona a imagem
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 200,
        minHeight: 200,
        quality: 50,
      );

      // Converte para base64
      final base64String = base64Encode(compressedBytes);

      setState(() {
        _profilePictureBase64 = base64String;
        _isSaving = false;
      });

      _showSuccessSnackBar('Foto adicionada com sucesso!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erro ao processar imagem. Tente novamente.');
    }
  }

  void _removeProfilePicture() {
    setState(() {
      _profilePictureBase64 = null;
    });
    _showSuccessSnackBar('Foto removida. Clique em Salvar para confirmar.');
  }

  Future<void> _savePreferences() async {
    try {
      await AuthService.updateUserProfile(
        nome: _nomeController.text,
        interesseNovosImoveis: _interesseNovosImoveis,
        interesseContato: _interesseContato,
      );
    } catch (e) {
      // Falha silenciosa - não queremos interromper o usuário
      debugPrint('Erro ao salvar preferências: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await AuthService.updateUserProfile(
        nome: _nomeController.text,
        telefone: _telefoneController.text.isEmpty
            ? null
            : _telefoneController.text,
        profilePicture: _profilePictureBase64,
        interesseNovosImoveis: _interesseNovosImoveis,
        interesseContato: _interesseContato,
      );

      setState(() => _isSaving = false);

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
        // Espera um pouco para mostrar o snackbar antes de voltar
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erro ao salvar alterações. Tente novamente.');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfilePicture() {
    ImageProvider? imageProvider;

    if (_profilePictureBase64 != null) {
      try {
        final bytes = base64Decode(_profilePictureBase64!);
        imageProvider = MemoryImage(Uint8List.fromList(bytes));
      } catch (e) {
        imageProvider = null;
      }
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações Pessoais'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfilePicture(),
                    const SizedBox(height: 40),

                    // Email field (read-only)
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name field
                    const Text(
                      'Nome *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        hintText: 'Digite seu nome',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, preencha todos os campos obrigatórios.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone field
                    const Text(
                      'Telefone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Digite seu telefone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Preferências',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Tenho interesse em novos imóveis'),
                      value: _interesseNovosImoveis,
                      onChanged: (value) {
                        setState(() {
                          _interesseNovosImoveis = value ?? false;
                        });
                        _savePreferences();
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Gostaria de ser contatado para futuras oportunidades',
                      ),
                      value: _interesseContato,
                      onChanged: (value) {
                        setState(() {
                          _interesseContato = value ?? false;
                        });
                        _savePreferences();
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
