import 'package:flutter/material.dart';

class FormatifPage extends StatelessWidget {
  const FormatifPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi ke 5'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.red,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.yellow,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
