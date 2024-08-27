import 'package:biumerch_mobile_app/modul3/banner_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BannerModel>> getBanners() async {
    QuerySnapshot snapshot = await _firestore.collection('banners').get();
    return snapshot.docs.map((doc) => BannerModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
}