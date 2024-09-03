import '/modul1.2/common/widgets/login_signup.dart/custom_text.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';
import 'package:flutter/material.dart';

class TLoginHeader extends StatelessWidget {
  const TLoginHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(
          image: AssetImage(TImages.coreLogo),
        ),
        CustomText(
          text: TTexts.loginPageTitle,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: TColors.textBlack,
        ),
        SizedBox(height: TSizes.sm),
        CustomText(
          text: TTexts.loginpageSubTitle,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: TColors.textAccent,
        ),
      ],
    );
  }
}
