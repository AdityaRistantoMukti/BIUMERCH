import 'package:biumerch_mobile_app/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class TLoadingWidget extends StatelessWidget {
  const TLoadingWidget({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF62E703)),
          const SizedBox(height: TSizes.defaultSpace),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}