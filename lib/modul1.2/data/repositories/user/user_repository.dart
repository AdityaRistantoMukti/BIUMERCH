import '/modul1.2/features/authentication/models/signup/user_model.dart';
import '/modul1.2/utils/exceptions/firebase_exceptions.dart';
import '/modul1.2/utils/exceptions/format_exceptions.dart';
import '/modul1.2/utils/exceptions/platform_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class UserRepository extends GetxController{
  static UserRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user data';
    }
  }

  Future<void> updateUserRecord(UserModel user) async {
    try {
      await _db.collection('users').doc(user.idUser).update(user.toJson());
    } catch (e) {
      throw 'Failed to update user data';
    }
  }
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection('users').doc(user.idUser).set(user.toJson());
    } on FirebaseException catch (e){
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    }catch (e){
      throw 'Something went wrong. Please try again';
    }

  }

}