import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/common/widgets/login_signup.dart/custom_text_form_field.dart';
import '/modul1.2/features/authentication/controllers/forget_password/forget_password_controller.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import '/modul1.2/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Headings
            const CustomText(
              text: TTexts.forgetPassword,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TColors.textBlack,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            const CustomText(
              text: TTexts.forgetPasswordSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TColors.textAccent,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: TSizes.spaceBtwSections * 2),

            /// Text field
            Form(
              key: controller
                  .forgetPasswordFormKey, // Gunakan GlobalKey dari controller
              child: Column(
                children: [
                  CustomTextFormField(
                    controller: controller.email,
                    validator: TValidator.validateEmail,
                    hintText: TTexts.email,
                    prefixIcon: Iconsax.sms,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => controller.sendPasswordResetEmail(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Kirim',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
