import '/modul2/common/widget/success_dialog.dart';
import '/modul2/features/tarik_saldo/repositories/pembeli/tarik_saldo_pembeli_repository.dart';
import 'package:flutter/material.dart';
import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TarikSaldoPembeliController {
  final TarikSaldoPembeliRepository _repository = TarikSaldoPembeliRepository();

  Future<void> tarikSaldo(BuildContext context, TarikSaldoModel model,
      int currentBalance, VoidCallback onResetFields) async {
    try {
      // Ambil UID pengguna yang login dari FirebaseAuth untuk pembeli
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Pengguna tidak ditemukan");
      }

      String uid = currentUser.uid; // Gunakan UID untuk pembeli

      // Hitung biaya admin berdasarkan provider
      int biayaAdmin;
      if (model.provider == "Bank Central Asia (BCA)") {
        biayaAdmin = 0; // Tidak ada biaya admin untuk BCA
      } else if (model.provider == "Bank") {
        biayaAdmin = 2500; // Biaya admin untuk bank lainnya
      } else {
        biayaAdmin = 1000; // Biaya admin untuk virtual account
      }

      // Hitung uang diterima setelah dikurangi biaya admin
      int uangDiterima = model.nominal - biayaAdmin;

      // Buat model baru dengan UID pengguna
      TarikSaldoModel modelWithUID = TarikSaldoModel(
        transactorId: uid, // Gunakan UID pengguna sebagai transactorId
        namaPenerima: model.namaPenerima,
        nomorRekening: model.nomorRekening,
        provider: model.provider,
        nominal: model.nominal,
        biayaAdmin: biayaAdmin,
        uangDiterima: uangDiterima,
        status: "pending",
        tanggal: DateTime.now(),
        type: "pembeli", // Ganti type menjadi "pembeli"
        alasan: "", // Alasan kosong
        buktiBayar: "", // Bukti bayar kosong
      );

      // Lakukan penarikan saldo
      await _repository.tarikSaldo(modelWithUID);

      // Hitung saldo baru
      int newBalance = currentBalance - model.nominal;

      // Perbarui saldo pengguna (pembeli) di Firestore
      await _repository.updateBalance(uid, newBalance);

      // Tampilkan pop-up berhasil menggunakan SuccessDialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SuccessDialog(
            message: "Penarikan Berhasil!",
            onPressed: () {
              Navigator.of(context).pop();
              onResetFields();
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal melakukan penarikan saldo.')),
      );
    }
  }
}
