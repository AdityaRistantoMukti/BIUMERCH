import '/modul2/common/widget/success_dialog.dart';
import 'package:flutter/material.dart';
import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import '/modul2/features/tarik_saldo/repositories/toko/tarik_saldo_repository.dart';

class TarikSaldoController {
  final TarikSaldoRepository _repository = TarikSaldoRepository();

  Future<void> tarikSaldo(BuildContext context, TarikSaldoModel model,
      int currentBalance, VoidCallback onResetFields) async {
    try {
      // Ambil transactorId (sebelumnya idStore) dari repository
      String transactorId = await _repository.getIdStore();

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

      // Buat model baru dengan transactorId
      TarikSaldoModel modelWithIdStore = TarikSaldoModel(
        transactorId: transactorId, // Gunakan transactorId
        namaPenerima: model.namaPenerima,
        nomorRekening: model.nomorRekening,
        provider: model.provider,
        nominal: model.nominal,
        biayaAdmin: biayaAdmin,
        uangDiterima: uangDiterima,
        status: "pending",
        tanggal: DateTime.now(),
        type: "penjual", // Default value untuk type
        alasan: "", // Alasan kosong
        buktiBayar: "", // Bukti bayar kosong
      );

      // Lakukan penarikan saldo
      await _repository.tarikSaldo(modelWithIdStore);

      // Hitung saldo baru
      int newBalance = currentBalance - model.nominal;

      // Perbarui saldo balance di Firestore
      await _repository.updateBalance(transactorId, newBalance);

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
