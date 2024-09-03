import '/modul1.2/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TAnimationLoaderWidget extends StatelessWidget {
  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    required this.animation,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
  });

  final String text;
  final String animation;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView( // Tambahkan SingleChildScrollView
        child: ConstrainedBox( // Tambahkan ConstrainedBox
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible( // Gunakan Flexible untuk Lottie
                child: Lottie.asset(
                  animation,
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain, // Tambahkan fit
                ),
              ),
              const SizedBox(height: TSizes.defaultSpace),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.defaultSpace),
              if (showAction)
                SizedBox(
                  width: 250,
                  child: OutlinedButton(
                    onPressed: onActionPressed,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: const BorderSide(color: Color.fromARGB(255, 126, 30, 30)),
                    ),
                    child: Text(
                      actionText!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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