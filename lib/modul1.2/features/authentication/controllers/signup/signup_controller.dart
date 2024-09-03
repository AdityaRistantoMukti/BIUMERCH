import '/modul1.2/data/repositories/authentication/authentication_repository.dart';
import '/modul1.2/data/repositories/user/user_repository.dart';
import '/modul1.2/features/authentication/models/signup/user_model.dart';
import '/modul1.2/features/authentication/view/singup/verify_email.dart';
import '/modul1.2/utils/helpers/network_manager.dart';
import '/modul1.2/utils/helpers/t_loaders.dart';
import '/modul1.2/utils/popups/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// variables
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final phoneNumber = TextEditingController();
  final password = TextEditingController();

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// SIGNUP
  void signup() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
          'Kami Sedang Memproses Informasimu...');
      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Register user in the Firebase Authentication & Save user data in firebase
      final userCredetial =
          await AuthenticationRepository.instance.registerWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // save Authenticated user data in the firebase firestore
      final newUser = UserModel(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        idUser: userCredetial.user!.uid,
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: 'https://www.gravatar.com/avatar/?d=mp',
        balance: 0,
        isEmail: false,
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      // remove loader
      TFullScreenLoader.stopLoading();

      // show success message
      TLoaders.successSnackbar(
          title: 'Selamat',
          message:
              'Akun kamu berhasil dibuat! Verifikasi email kamu untuk melanjutkan.');

      // move to verify email screen
      Get.to(() => VerifyEmailView(email: email.text.trim()));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      // Show some Generic Error to the user
      TLoaders.errorSnackbar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
