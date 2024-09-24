import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';

class TarikSaldoDetailView extends StatelessWidget {
  final TarikSaldoModel withdrawal;

  const TarikSaldoDetailView({super.key, required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Penarikan',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Nutino',
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 0.5,
                  offset: const Offset(0, 1), // changes position of shadow
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildDetailCard(
                  context, 'Nama Penerima', withdrawal.namaPenerima),
              _buildDivider(),
              _buildDetailCard(
                  context, 'Nomor Rekening', withdrawal.nomorRekening),
              _buildDivider(),
              _buildDetailCard(context, 'Provider', withdrawal.provider),
              _buildDivider(),
              _buildDetailCard(context, 'Nominal',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(withdrawal.nominal)}',
                  isBold: true),
              _buildDivider(),
              _buildDetailCard(context, 'Biaya Admin',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(withdrawal.biayaAdmin)}'),
              _buildDivider(),
              _buildDetailCard(context, 'Uang Diterima',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(withdrawal.uangDiterima)}',
                  isBold: true),
              _buildDivider(),
              _buildStatusCard(), // Menyesuaikan status card
              _buildDivider(),
              _buildDetailCard(
                  context,
                  'Tanggal',
                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                      .format(withdrawal.tanggal)),
              _buildDivider(),
              _buildDetailCard(context, 'Tipe Transaksi', withdrawal.type),
              _buildDivider(),
              _buildDetailCard(
                  context,
                  'Alasan',
                  withdrawal.alasan.isNotEmpty
                      ? withdrawal.alasan
                      : 'Tidak ada alasan'),
              _buildDivider(),
              _buildBuktiBayarSection(
                  context), // Bagian Bukti Bayar yang dimodifikasi
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Bagian Bukti Bayar
  Widget _buildBuktiBayarSection(BuildContext context) {
    // Cek jika bukti bayar tidak ada
    if (withdrawal.buktiBayar.isEmpty) {
      return _buildDetailCard(context, 'Bukti Bayar', 'Belum ada bukti bayar');
    } else {
      // Tampilkan ikon gambar jika bukti bayar ada
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bukti Bayar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Nunito',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.image, color: Colors.blue),
              onPressed: () {
                _showImageOverlay(context, withdrawal.buktiBayar);
              },
            ),
          ],
        ),
      );
    }
  }

  // Fungsi untuk menampilkan overlay gambar bukti bayar
  void _showImageOverlay(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black, // Overlay berwarna hitam
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover, // Menyesuaikan gambar dengan baik
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                      'Gagal memuat gambar'); // Jika gambar gagal dimuat
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:
                    const Text("Tutup", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Divider antara elemen
  Widget _buildDivider() {
    return const Divider(
      color: Colors.grey,
      height: 1,
    );
  }

  // Fungsi untuk menampilkan elemen detail
  Widget _buildDetailCard(BuildContext context, String title, String value,
      {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan status penarikan
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'Nunito',
            ),
          ),
          Row(
            children: [
              Icon(
                _getStatusIcon(withdrawal.status),
                color: _getStatusColor(withdrawal.status),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(withdrawal.status),
                style: TextStyle(
                  fontSize: 16,
                  color: _getStatusColor(withdrawal.status),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan ikon status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancel':
        return Icons.cancel;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Fungsi untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'cancel':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk mendapatkan teks status
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'cancel':
        return 'Penarikan Dibatalkan';
      case 'success':
        return 'Penarikan Berhasil';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[350],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(withdrawal.status),
            color: _getStatusColor(withdrawal.status),
            size: 40,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Penarikan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                _getStatusText(withdrawal.status),
                style: TextStyle(
                  fontSize: 18,
                  color: _getStatusColor(withdrawal.status),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
