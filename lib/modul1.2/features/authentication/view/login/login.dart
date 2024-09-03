import '/modul1.2/common/styles/spacing_styles.dart';
import '/modul1.2/common/widgets/login_signup.dart/form_divider.dart';
import '/modul1.2/common/widgets/login_signup.dart/social_buttons.dart';
import '/modul1.2/features/authentication/view/login/widgets/login_form.dart';
import '/modul1.2/features/authentication/view/login/widgets/login_header.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(1.0),
                ],
                stops: const [0.0, 0.0, 0.4],
              ),
            ),
          ),
          // Content
          const SingleChildScrollView(
            child: Padding(
              padding: TSpacingStyle.paddingWithAppBarHeight,
              child: Column(
                children: [
                  /// Logo, Title & Sub-Title
                  TLoginHeader(),
                  /// Form
                  TLoginForm(),
                  /// Divider
                  TFormDivider(),
                  SizedBox(height: TSizes.spaceBtwSections),
                  /// Footer
                  TSocialButtons()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
