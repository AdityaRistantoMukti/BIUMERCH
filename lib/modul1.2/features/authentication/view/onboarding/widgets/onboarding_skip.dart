import '/modul1.2/features/authentication/controllers/onboarding/onboarding_controller.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/device/device_utility.dart';
import 'package:flutter/material.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: TDeviceUtils.getAppBarHeight(),
        right: TSizes.defaultSpace,
        child: TextButton(
          onPressed: () => OnboardingController.instance.skipPage(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5F5F5F), // Warna teks tombol
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
          child: const Text(
            'Skip',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ));
  }
}
