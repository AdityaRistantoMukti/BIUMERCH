import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NominalPenarikanField extends StatelessWidget {
  final TextEditingController controller;
  final NumberFormat formatCurrency;
  final ValueChanged<String> onChanged;

  NominalPenarikanField({
    required this.controller,
    required this.formatCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Nominal Penarikan',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
