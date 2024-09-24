import 'package:cloud_firestore/cloud_firestore.dart';

class TarikSaldoModel {
  final String transactorId; // Ubah dari idstore menjadi transactorId
  final String namaPenerima;
  final String nomorRekening;
  final String provider;
  final int nominal;
  final int biayaAdmin;
  final int uangDiterima;
  final String status;
  final DateTime tanggal;
  final String type; // Tambahkan field type
  final String alasan; // Tambahkan field alasan
  final String buktiBayar; // Tambahkan field buktiBayar

  TarikSaldoModel({
    required this.transactorId,
    required this.namaPenerima,
    required this.nomorRekening,
    required this.provider,
    required this.nominal,
    required this.biayaAdmin,
    required this.uangDiterima,
    required this.status,
    required this.tanggal,
    this.type = "penjual", // Default value
    this.alasan = "", // Default value kosong
    this.buktiBayar = "", // Default value kosong
  });

  Map<String, dynamic> toMap() {
    return {
      'transactorId': transactorId, // Ubah dari idstore menjadi transactorId
      'nama_penerima': namaPenerima,
      'nomor_rekening': nomorRekening,
      'provider': provider,
      'nominal': nominal,
      'biaya_admin': biayaAdmin,
      'uang_diterima': uangDiterima,
      'tanggal': Timestamp.fromDate(tanggal),
      'status': status,
      'type': type, // Tambahkan type ke map
      'alasan': alasan, // Tambahkan alasan ke map
      'buktiBayar': buktiBayar, // Tambahkan buktiBayar ke map
    };
  }

  factory TarikSaldoModel.fromFirestore(Map<String, dynamic> json) {
    return TarikSaldoModel(
      transactorId: json['transactorId'] ?? '', // Ubah dari idstore
      namaPenerima: json['nama_penerima'] ?? '',
      nomorRekening: json['nomor_rekening'] ?? '',
      provider: json['provider'] ?? '',
      nominal: (json['nominal'] ?? 0).toInt(),
      biayaAdmin: (json['biaya_admin'] ?? 0).toInt(),
      uangDiterima: (json['uang_diterima'] ?? 0).toInt(),
      status: json['status'] ?? '',
      tanggal: (json['tanggal'] as Timestamp).toDate(),
      type: json['type'] ?? 'penjual',
      alasan: json['alasan'] ?? '', // Ambil data alasan
      buktiBayar: json['buktiBayar'] ?? '', // Ambil data buktiBayar
    );
  }
}