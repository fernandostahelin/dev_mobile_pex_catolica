import 'package:flutter/material.dart';

class InformacoesTela extends StatelessWidget {
  const InformacoesTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Tela de Informações',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Esta tela será implementada pela equipe',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
