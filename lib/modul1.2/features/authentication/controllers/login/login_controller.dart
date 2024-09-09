import 'package:biumerch_mobile_app/modul1.2/data/repositories/authentication/authentication_repository.dart';
import 'package:biumerch_mobile_app/modul1.2/features/personalization/controllers/user_controller.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/helpers/network_manager.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/helpers/t_loaders.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/popups/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  /// Variables
  final rememberMe = false.obs; 
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = Get.put(UserController());
  

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
  }

  /// -- Email and Password SignIn
  Future<void> loginWithEmailAndPassword() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Sedang masuk ke akun Anda...');
      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackbar(
            title: 'No Internet',
            message: 'Please check your internet connection.');
        return;
      }

      // Form Validation
      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Save Data if Remember Me si selected
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      //  Login user using Email & Password Authentication
      final userCredential =
          await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // Remove Loader
      TFullScreenLoader.stopLoading();
      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackbar(title: 'Oh Snap', message: e.toString());
    }
  }

  Future<void> googleSignIn() async {
    try {
      TFullScreenLoader.openLoadingDialog('Sedang masuk ke akun Anda...');

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackbar(
            title: 'No Internet',
            message: 'Please check your internet connection.');
        return;
      }

      await _googleSignIn.signOut();
      
      // Memulai proses sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan proses sign-in
        return;
      }

      // Goole Authentication
      final userCredentials =
          await AuthenticationRepository.instance.signInWIthGoogle();

      if (userCredentials.user == null) {
        throw 'Failed to sign in with Google. Please try again.';
      }

      // Save User Record
      await userController.saveUserRecord(userCredentials);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      print('Detailed error during Google Sign In: $e');
      TLoaders.errorSnackbar(
          title: 'Sign In Failed',
          message: 'An error occurred during sign in. Please try again.');
    }
  }
}
