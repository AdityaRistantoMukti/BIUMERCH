import '/modul1.2/utils/constants/color.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextAlign textAlign;

  const CustomText({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w400,
    this.color = TColors.textAccent,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      ),
      textAlign: textAlign,
    );
  }
}
