import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/features/authentication/controllers/forget_password/forget_password_controller.dart';
import '/modul1.2/features/authentication/view/login/login.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import '/modul1.2/utils/helpers/helper_function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPassword extends StatelessWidget {
  const ResetPassword({super.key, required this.email});
  final String email;
  @override
  Widget build(BuildContext context) {
        Get.put(ForgetPasswordController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(CupertinoIcons.clear))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Image
              Image(
                image: const AssetImage(TImages.successEmail),
                width: THelperFunction.screenWidth(context) * 0.2,
              ),

              /// Title & Subtitle
              CustomText(
                text: email,
                textAlign: TextAlign.center,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TColors.textBlack,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              const CustomText(
                text: TTexts.resetPasswordTitle,
                textAlign: TextAlign.center,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TColors.textBlack,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              const CustomText(
                text: TTexts.resetPasswordSubTitle,
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
                  onPressed: () => Get.offAll(() => const LoginView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => ForgetPasswordController.instance.resendPasswordResetEmail(email),
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
