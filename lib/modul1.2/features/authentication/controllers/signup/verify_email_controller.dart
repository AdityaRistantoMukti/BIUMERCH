import 'dart:async';
import '/modul1.2/common/widgets/success_screen/success_view.dart';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/text_string.dart';
import '/modul1.2/utils/helpers/t_loaders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  // Send Email Whenever Verify View appears & set Timer for auto redirect
  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  /// Send Email Verification Link
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      TLoaders.successSnackbar(
          title: 'Email Terkirim',
          message: 'Silahkan cek inbox Kamu dan verifikasi email.');
    } catch (e) {
      TLoaders.errorSnackbar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Timer to automatically redirect on email verification
  void setTimerForAutoRedirect() {
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.emailVerified ?? false) {
      timer.cancel();
      await AuthenticationRepository.instance.updateIsEmailVerified();
      Get.off(
        () => SuccessView(
          image: TImages.successfullyAnimation,
          title: TTexts.successVerifyTitle,
          subTitle: TTexts.successVerifySubTitle,
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    }
  });
}


  /// Manually check if email verified
  checkEmailVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(() => SuccessView(
            image: TImages.successfullyAnimation,
            title: TTexts.successVerifyTitle,
            subTitle: TTexts.successVerifySubTitle,
            onPressed: () => AuthenticationRepository.instance.screenRedirect(),
          ));
    }
  }
}
