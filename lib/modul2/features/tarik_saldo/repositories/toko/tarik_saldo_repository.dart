import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tarik_saldo_model.dart';

class TarikSaldoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk mengambil idStore dari stores berdasarkan UID pengguna yang login
  Future<String> getIdStore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      // Ambil store yang memiliki ownerId = uid yang login
      QuerySnapshot snapshot = await _firestore
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Kembalikan idStore (document ID)
      } else {
        throw Exception('Store tidak ditemukan untuk UID tersebut.');
      }
    } else {
      throw Exception('Pengguna tidak login.');
    }
  }

  // Fungsi untuk melakukan penarikan saldo
  Future<void> tarikSaldo(TarikSaldoModel model) async {
    try {
      await _firestore.collection('withdrawal').add(model.toMap());
    } catch (e) {
      throw Exception('Gagal melakukan penarikan saldo.');
    }
  }

  // Fungsi untuk memperbarui saldo balance di stores
  Future<void> updateBalance(String idStore, int newBalance) async {
    try {
      await _firestore.collection('stores').doc(idStore).update({
        'balance': newBalance,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui saldo.');
    }
  }

  // Fungsi untuk mengambil balance secara realtime dari store berdasarkan UID pengguna yang login
  Stream<DocumentSnapshot> getTotalPendapatanStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      return _firestore
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.first;
            } else {
              throw Exception('Store tidak ditemukan untuk UID tersebut.');
            }
          });
    } else {
      throw Exception('Pengguna tidak login.');
    }
  }
}

