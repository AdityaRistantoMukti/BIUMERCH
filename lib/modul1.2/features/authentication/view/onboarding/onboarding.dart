import '/modul1.2/features/authentication/controllers/onboarding/onboarding_controller.dart';
import '/modul1.2/features/authentication/view/onboarding/widgets/onboarding_dot_navgation.dart';
import '/modul1.2/features/authentication/view/onboarding/widgets/onboarding_page.dart';
import '/modul1.2/features/authentication/view/onboarding/widgets/onboarding_skip.dart';
import '/modul1.2/features/authentication/view/onboarding/widgets/onboatding_next_button.dart';
import '/modul1.2/utils/constants/image_string.dart';
import '/modul1.2/utils/constants/text_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Horizontal Scrollable Pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              OnBoardingPage(
                image: TImages.onboarding1,
                title: TTexts.onBoardingTitle1,
                subTitle: TTexts.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: TImages.onboarding2,
                title: TTexts.onBoardingTitle2,
                subTitle: TTexts.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: TImages.onboarding3,
                title: TTexts.onBoardingTitle3,
                subTitle: TTexts.onBoardingSubTitle3,
              ),
            ],
          ),

          /// Skip Button
          const OnBoardingSkip(),

          /// Dot Navigation SmoothPageIndicator
          const OnBoardingDotNavigation(),

          /// Circular Button
          const OnBoardingNextButton(),
        ],
      ),
    );
  }
}

