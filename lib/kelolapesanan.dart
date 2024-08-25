import 'package:flutter/material.dart';

class KelolaPesananScreen extends StatelessWidget {
  const KelolaPesananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(
            color: Color(0xFF319F43), // Warna hijau
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        backgroundColor: Colors.white, // Background AppBar putih
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          OrderBox(
            imageUrl: 'assets/images/geprek.png',
            namaBarang: 'Ayam Geprek',
            namaPemesan: 'Sekar',
            noTelepon: '+62 812-3456-7890',
            totalPesanan: 'Rp 200.000',
            opsi: 'Paha',
            catatan: 'Tidak Terlalu Pedas',
            metodePembayaran: 'Bank BCA',
            jumlahPembayaran: 'Rp 200.000',
          ),
          OrderBox(
            imageUrl: 'assets/images/esteh.jpeg',
            namaBarang: 'Es Teh',
            namaPemesan: 'Acep',
            noTelepon: '+62 811-2345-6789',
            totalPesanan: 'Rp 150.000',
            opsi: 'Less Sugar',
            catatan: 'tidak ada.',
            metodePembayaran: 'COD',
            jumlahPembayaran: 'Rp 150.000',
          ),
          OrderBox(
            imageUrl: 'assets/images/katsu.png',
            namaBarang: 'Ayam Katsu',
            namaPemesan: 'Melin',
            noTelepon: '+62 878-7676-3728',
            totalPesanan: 'Rp 100.000',
            opsi: 'Dada',
            catatan: 'Sedang',
            metodePembayaran: 'Bank BRI',
            jumlahPembayaran: 'Rp 100.000',
          ),
          OrderBox(
            imageUrl: 'assets/images/senja.jpg',
            namaBarang: 'Jamu Senja',
            namaPemesan: 'Sobari',
            noTelepon: '+62 813-3675-9856',
            totalPesanan: 'Rp 50.000',
            opsi: 'Kunyit',
            catatan: '1 Gelas',
            metodePembayaran: 'Cash',
            jumlahPembayaran: 'Rp 50.000',
          ),
          // Tambahkan OrderBox lain sesuai kebutuhan
        ],
      ),
    );
  }
}

class OrderBox extends StatefulWidget {
  final String imageUrl;
  final String namaBarang;
  final String namaPemesan;
  final String noTelepon;
  final String totalPesanan;
  final String opsi;
  final String catatan;
  final String metodePembayaran;
  final String jumlahPembayaran;

  const OrderBox({super.key, 
    required this.imageUrl,
    required this.namaBarang,
    required this.namaPemesan,
    required this.noTelepon,
    required this.totalPesanan,
    required this.opsi,
    required this.catatan,
    required this.metodePembayaran,
    required this.jumlahPembayaran,
  });

  @override
  _OrderBoxState createState() => _OrderBoxState();
}

class _OrderBoxState extends State<OrderBox> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          ListTile(
            leading: Image.asset(
              widget.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(widget.namaBarang),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemesan: ${widget.namaPemesan}'),
                Text('No. Telepon: ${widget.noTelepon}'),
                Text('Total: ${widget.totalPesanan}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.green,
              ),
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text('Opsi: ${widget.opsi}'),
                  const SizedBox(height: 4),
                  Text('Catatan: ${widget.catatan}'),
                  const SizedBox(height: 4),
                  Text('Metode Pembayaran: ${widget.metodePembayaran}'),
                  const SizedBox(height: 4),
                  Text('Jumlah Pembayaran: ${widget.jumlahPembayaran}'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
