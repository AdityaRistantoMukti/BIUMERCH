// Tambahkan widget Total Pendapatan
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalPendapatanWidget extends StatelessWidget {
  final int totalPendapatan;

  const TotalPendapatanWidget({super.key, required this.totalPendapatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 60.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'SALDO :',
            style: TextStyle(
              fontFamily: 'Nutino',
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rp${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalPendapatan)}',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
