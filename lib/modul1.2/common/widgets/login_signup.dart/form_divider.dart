import '/modul1.2/utils/constants/text_string.dart';
import 'package:flutter/material.dart';

class TFormDivider extends StatelessWidget {
  const TFormDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Garis
        Flexible(
          child: Divider(
            color: Color(0xFFD9D9D9),
            thickness: 1.5,
            indent: 5,
            endIndent: 5,
          ),
        ),

        // Text
        Text(
          TTexts.or,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: Color(0xFF0B4D3B), 
          ),
        ),

        // Garis
        Flexible(
          child: Divider(
            color: Color(0xFFD9D9D9),
            thickness: 1.5,
            indent: 5,
            endIndent: 5,
          ),
        ),
      ],
    );
  }
}

