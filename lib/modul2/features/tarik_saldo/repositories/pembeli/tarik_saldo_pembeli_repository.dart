import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tarik_saldo_model.dart';

class TarikSaldoPembeliRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk melakukan penarikan saldo (untuk pembeli)
  Future<void> tarikSaldo(TarikSaldoModel model) async {
    try {
      // Validasi pengguna yang login
      User? user = _auth.currentUser;
      if (user == null) throw Exception('Pengguna tidak login.');

      // Menambahkan data penarikan saldo ke koleksi `withdrawal`
      await _firestore.collection('withdrawal').add(model.toMap());
    } catch (e) {
      throw Exception('Gagal melakukan penarikan saldo.');
    }
  }

  // Fungsi untuk memperbarui saldo balance di users (untuk pembeli)
  Future<void> updateBalance(String uid, int newBalance) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': newBalance,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui saldo.');
    }
  }

  // Fungsi untuk mengambil balance secara realtime dari users berdasarkan UID pengguna yang login
  Stream<DocumentSnapshot> getTotalPendapatanStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      return _firestore.collection('users').doc(uid).snapshots();
    } else {
      throw Exception('Pengguna tidak login.');
    }
  }
}
