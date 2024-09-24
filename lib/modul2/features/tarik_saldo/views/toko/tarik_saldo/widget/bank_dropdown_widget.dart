import 'package:flutter/material.dart';

class BankDropdownWidget extends StatelessWidget {
  final List<Map<String, dynamic>> banks;
  final String? selectedBank;
  final ValueChanged<String?> onChanged;

  BankDropdownWidget({
    required this.banks,
    required this.selectedBank,
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedBank,
        hint: const Text('Pilih Bank / E-Wallet'),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: banks.map((bank) {
          return DropdownMenuItem<String>(
            value: bank['name'],
            child: Row(
              children: [
                bank['logo'] != null
                    ? Image.asset(bank['logo'], width: 30, height: 30)
                    : Icon(bank['icon'], color: bank['color']),
                const SizedBox(width: 10),
                Text(bank['name']),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
