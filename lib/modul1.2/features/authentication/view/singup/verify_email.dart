import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart';
import '/modul1.2/features/authentication/controllers/signup/verify_email_controller.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import '/modul1.2/utils/helpers/helper_function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () => AuthenticationRepository.instance.logout(),
              icon: const Icon(CupertinoIcons.clear))
        ],
      ),
      body: SingleChildScrollView(
        // padding to give default equal space on all sides in all screens
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Image
              Image(
                image: const AssetImage(TImages.verifyEmail1),
                width: THelperFunction.screenWidth(context) * 0.6,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Title & Subtitle
              const CustomText(
                text: TTexts.verifyEmailTitle,
                textAlign: TextAlign.center,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TColors.textBlack,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              CustomText(
                text: email ?? '',
                textAlign: TextAlign.center,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B4D3B),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              const CustomText(
                text: TTexts.verifyEmailSubTitle,
                textAlign: TextAlign.center,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: TColors.textAccent,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.checkEmailVerificationStatus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    TTexts.verifyEmailBtnTitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => controller.sendEmailVerification(),
                  child: const CustomText(
                    text: TTexts.resendEmail,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TColors.textAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
