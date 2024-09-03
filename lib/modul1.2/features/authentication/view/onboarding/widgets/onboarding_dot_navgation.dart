import '/modul1.2/features/authentication/controllers/onboarding/onboarding_controller.dart';
import '/modul1.2./utils/constants/sizes.dart';
import '/modul1.2/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;

    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight(context) + 25,
      left: TSizes.defaultSpace,
      child: SmoothPageIndicator(
        count: 3,
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        effect: const ExpandingDotsEffect(
          activeDotColor: Color(0xFF62E703),
          dotHeight: 6,
          spacing: 4,
          expansionFactor: 2,
        ),
      ),
    );
  }
}
