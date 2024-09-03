import '/modul1.2/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import '/modul1.2/utils/helpers/helper_function.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        children: [
          Image(
            width: THelperFunction.screenWidth(context) * 0.8,
            height: THelperFunction.screenHeight(context) * 0.6,
            image: AssetImage(image),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800, // NunitoExtraBold
              fontSize: 24, // Contoh ukuran font
              color: Color(0xFF0B4D3B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: TSizes.spaceBtwItems,
          ),
          Text(
            subTitle,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF5F5F5F),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
