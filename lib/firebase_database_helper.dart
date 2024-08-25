import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDatabaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> insertProfile(String userId, Map<String, dynamic> profile) async {
    try {
      await _firestore.collection('users').doc(userId).set(profile, SetOptions(merge: true));
    } catch (e) {
      print('Error inserting profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(userId).get();

      if (snapshot.exists) {
        return snapshot.data();
      } else {
        print('Profile not found');
        return null;
      }
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
}
