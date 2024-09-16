import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class OrderService {
  Stream<List<QuerySnapshot>> getCombinedStream(String userId) {
    final transactionStream = FirebaseFirestore.instance
        .collection('transaction')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return transactionStream.asyncMap((querySnapshot) async {
      List<QuerySnapshot> itemsSnapshots = await Future.wait(
        querySnapshot.docs.map((doc) => doc.reference.collection('items').get())
      );
      return [querySnapshot, ...itemsSnapshots];
    });
  }
}
