import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/common/widgets/login_signup.dart/form_divider.dart';
import '/modul1.2/common/widgets/login_signup.dart/social_buttons.dart';
import '/modul1.2/features/authentication/view/singup/widgets/signup_form.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import 'package:flutter/material.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(TImages.backgroundAuth),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(1.0),
                ],
                stops: const [0.0, 0.0, 0.3],
              ),
            ),
          ),

          /// Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: TColors.textBlack),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    const SizedBox(height: TSizes.spaceBtwItems),

                    /// Title
                    const CustomText(
                      text: TTexts.signupTitle1,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TColors.textBlack,
                    ),
                    const CustomText(
                      text: TTexts.signupTitle2,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TColors.textBlack,
                    ),
                    const CustomText(
                      text: TTexts.signupSubTitle,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: TColors.textAccent,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// form
                    const TSignupForm(),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Divider
                    const TFormDivider(),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    /// Social Buttons
                    const TSocialButtons(),

                    ///
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
