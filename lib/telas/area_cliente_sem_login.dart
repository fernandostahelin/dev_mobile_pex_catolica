import 'package:flutter/material.dart';

class AreaClienteSemLogin extends StatelessWidget {
  const AreaClienteSemLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Espaçamento superior
              const SizedBox(height: 40),

              // Placeholder da imagem/logo
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.landscape,
                  size: 80,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Título
              const Text(
                'Área do Cliente',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 60),

              // Botão "Não sou cliente"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/cadastro');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black54, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Não sou cliente',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão "Já sou cliente"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo, width: 1),
                    backgroundColor: Colors.indigo[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Já sou cliente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Espaçamento para empurrar a navegação inferior
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Destaca a aba "Área do Cliente"
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
          } else if (index == 1) {
            Navigator.pushNamed(context, '/area-cliente-sem-login');
          }
        },
      ),
    );
  }
}
