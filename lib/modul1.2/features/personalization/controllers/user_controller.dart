import 'package:biumerch_mobile_app/modul1.2/data/repositories/user/user_repository.dart';
import 'package:biumerch_mobile_app/modul1.2/features/authentication/models/signup/user_model.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/helpers/t_loaders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  static UserCredential get instance => Get.find();
  final userRepository = Get.put(UserRepository());

  // Save user Record from any Registration provider
  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials?.user == null) {
        throw 'User information is not available';
      }

      final user = userCredentials!.user!;
      final existingUser = await userRepository.getUserById(user.uid);

      if (existingUser != null) {
        // User already exists in Firestore, update data if necessary
        // (e.g., update profile picture, balance, etc.)
        final updatedUser = existingUser.copyWith(
        );

        await userRepository.updateUserRecord(updatedUser);
      } else {
        // User doesn't exist in Firestore, create new record
        final nameParts = UserModel.nameParts(user.displayName ?? '');
        final username = UserModel.generateUsername(user.displayName ?? '');

        final newUser = UserModel(
          firstName: nameParts.isNotEmpty ? nameParts[0] : '',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          idUser: user.uid,
          username: username,
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
          profilePicture: user.photoURL ?? '',
          balance: 0,
          isEmail: true,
        );

        await userRepository.saveUserRecord(newUser);
      }
    } catch (e) {
      print('Error saving user record: $e');
      TLoaders.warningSnackbar(
        title: 'Data not saved',
        message: 'Something went wrong while saving your information. You can re-save your data in your Profile',
      );
    }
  }
}


