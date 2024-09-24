import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onPressed;

  const SuccessDialog({
    super.key,
    required this.message,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 50),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 18)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onPressed,
          child: const Text("OK"),
        ),
      ],
    );
  }
}
