import 'package:biumerch_mobile_app/modul1.2/data/repositories/authentication/authentication_repository.dart';
import 'package:biumerch_mobile_app/modul1.2/features/authentication/view/password_configuration/reset_password.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/helpers/network_manager.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/helpers/t_loaders.dart';
import 'package:biumerch_mobile_app/modul1.2/utils/popups/full_screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// Send Reset Password Email
  sendPasswordResetEmail() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Sedang memproses permintaan Anda....');

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
      if (!forgetPasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email: email.text.trim());

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Screen
      TLoaders.successSnackbar(title: 'Email Terkirim', message: 'Tautan untuk mengatur ulang kata sandi telah dikirim ke email Anda.');

      // Redirect
      Get.to(() => ResetPassword(email: email.text.trim()));

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackbar(title: 'Oh Snap', message: e.toString());
    }
  }

  resendPasswordResetEmail(String email) async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('Sedang memproses permintaan Anda....');

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackbar(
            title: 'No Internet',
            message: 'Please check your internet connection.');
        return;
      }

      // Send Email to Reset Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email: email);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Screen
      TLoaders.successSnackbar(title: 'Email Terkirim', message: 'autan untuk mengatur ulang kata sandi telah dikirim ke email Anda.');

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackbar(title: 'Oh Snap', message: e.toString());
    }
  }
}
