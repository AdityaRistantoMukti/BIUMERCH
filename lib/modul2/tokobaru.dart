import '/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'daftar_toko.dart'; // Import halaman DaftarTokoPage

class TokoBaruPage extends StatelessWidget {
  const TokoBaruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Menghilangkan bayangan AppBar
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back, // Icon back
            color: Colors.black, // Warna hitam untuk icon back
          ),
          onPressed: () {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BottomNavigation(selectedIndex: 3), 
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.white, // Latar belakang putih
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Icon toko di bagian atas
            const Icon(
              Icons.storefront, // Menggunakan ikon toko
              size: 100,
              color: Color(0xFF62E703), // Warna hijau sesuai dengan kode warna yang diberikan
            ),
            const SizedBox(height: 24),
            const Text(
              'Buka Toko',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Warna teks judul hitam
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Mulai langkah pertamamu di sini! Buka toko kampusmu dan jangkau lebih banyak teman-teman dengan cara mengelola bisnis semudah mengirim pesan di grup chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, // Ukuran font deskripsi lebih kecil
                color: Colors.black54, // Warna teks deskripsi abu-abu
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
                  backgroundColor: const Color(0xFF62E703), // Warna hijau sesuai kode warna
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Sudut membulat sesuai gambar
                  ),
                ),
                child: const Text(
                  'Buka Toko',
                  style: TextStyle(
                    fontSize: 16, // Ukuran font tombol lebih besar
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
