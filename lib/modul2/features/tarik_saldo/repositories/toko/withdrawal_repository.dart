import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getIdStoreByOwnerId(String uid) async {
    try {
      print('Fetching store for ownerId: $uid');
      QuerySnapshot snapshot = await _firestore
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Store found: ${snapshot.docs.first['idstore']}');
        return snapshot.docs.first['idstore'];
      } else {
        print('No store found for ownerId: $uid');
      }
      return null;
    } catch (e) {
      print('Error fetching store: $e');
      return null;
    }
  }

  Future<List<TarikSaldoModel>> fetchWithdrawalsByStoreId(String idStore) async {
    try {
      print('Fetching withdrawals for storeId: $idStore');
      QuerySnapshot snapshot = await _firestore
          .collection('withdrawal')
          .where('transactorId', isEqualTo: idStore)
          .orderBy('tanggal', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Withdrawals found: ${snapshot.docs.length}');
      } else {
        print('No withdrawals found for storeId: $idStore');
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
