import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalPembeliRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mengambil daftar penarikan berdasarkan UID pengguna yang login
  Future<List<TarikSaldoModel>> fetchWithdrawalsByUserId(String uid) async {
    try {
      print('Fetching withdrawals for user with UID: $uid');
      QuerySnapshot snapshot = await _firestore
          .collection('withdrawal')
          .where('transactorId', isEqualTo: uid)  // Gunakan UID pengguna sebagai transactorId
          .orderBy('tanggal', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Withdrawals found: ${snapshot.docs.length}');
      } else {
        print('No withdrawals found for userId: $uid');
      }

      return snapshot.docs.map((doc) {
        return TarikSaldoModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching withdrawals: $e');
      return [];
    }
  }
}
