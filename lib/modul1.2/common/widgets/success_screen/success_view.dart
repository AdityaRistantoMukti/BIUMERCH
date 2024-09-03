import '/modul1.2/common/styles/spacing_styles.dart';
import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import '/modul1.2/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessView extends StatelessWidget {
  const SuccessView(
      {super.key,
      required this.image,
      required this.title,
      required this.subTitle,
      required this.onPressed});

  final String image, title, subTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight * 2,
          child: Column(
            children: [
              /// Image
              Lottie.asset(
                image,
                width: THelperFunction.screenWidth(context) * 0.6,
              ),

              /// Title & Subtitle
              CustomText(
                text: title,
                textAlign: TextAlign.center,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TColors.textBlack,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              CustomText(
                text: subTitle,
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
                  onPressed: onPressed,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
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
