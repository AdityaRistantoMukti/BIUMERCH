import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'verifikasi_otp.dart';

class GantiEmailScreen extends StatefulWidget {
  final String userId;

  const GantiEmailScreen({super.key, required this.userId});

  @override
  _GantiEmailScreenState createState() => _GantiEmailScreenState();
}

class _GantiEmailScreenState extends State<GantiEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false; // To control loading state

  String? _otp;

  String generateOTP(int length) {
    final Random random = Random();
    const String digits = '0123456789';
    return List.generate(length, (index) => digits[random.nextInt(digits.length)]).join();
  }

  Future<void> sendOTP(String email) async {
    _otp = generateOTP(6);
    print('Generated OTP: $_otp');

    try {
      // Save OTP to Firestore
      await FirebaseFirestore.instance.collection('otps').doc(widget.userId).set({
        'email': email,
        'otp': _otp,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('OTP saved to Firestore');

      // SMTP Server configuration
      final smtpServer = SmtpServer(
        'smtp.mailersend.net',
        port: 587,
        username: 'MS_dGgAjm@trial-z3m5jgrrvyzgdpyo.mlsender.net',
        password: 'gmjwwTg6vWgPg34v',
      );

      // Create the email message
      final message = Message()
        ..from = const Address('MS_dGgAjm@trial-z3m5jgrrvyzgdpyo.mlsender.net', 'Your App Name')
        ..recipients.add(email)
        ..subject = 'Your OTP Code'
        ..text = 'Your OTP code is $_otp';

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('OTP sent successfully: $sendReport');
    } on MailerException catch (e) {
      print('Failed to send OTP: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  void _onLanjutPressed() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan email baru')),
      );
      return;
    }

    setState(() {
      _isSending = true; // Start loading
    });

    await sendOTP(_emailController.text);

    setState(() {
      _isSending = false; // Stop loading
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifikasiOTPScreen(
          email: _emailController.text,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ganti Email',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800, // Nunito Extra Bold
            fontSize: 20,
            color: Color(0xFF000000),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Masukkan Email Baru',
                labelStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700, // Nunito Bold
                  fontSize: 16,
                  color: Color(0xFF0B4D3B),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                fillColor: Colors.grey[200],
                filled: true,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _onLanjutPressed, // Disable button during loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Lanjut',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800, // Nunito Extra Bold
                          fontSize: 20,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
