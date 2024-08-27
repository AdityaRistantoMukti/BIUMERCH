import 'package:flutter/material.dart';
import 'daftar_toko.dart'; // Import halaman DaftarTokoPage

class TokoBaruPage extends StatelessWidget {
  const TokoBaruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Buka Toko',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mulai langkah pertamamu di sini! Buka toko kampusmu dan jangkau lebih banyak teman-teman dengan cara mengelola bisnis semudah mengirim pesan di grup chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DaftarTokoPage()), // Navigasi ke halaman DaftarTokoPage
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF319F43),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Buka Toko'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
