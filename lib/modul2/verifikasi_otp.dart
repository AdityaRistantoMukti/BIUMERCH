import '/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class VerifikasiOTPScreen extends StatefulWidget {
  final String email;
  final String userId;

  const VerifikasiOTPScreen({super.key, required this.email, required this.userId});

  @override
  _VerifikasiOTPScreenState createState() => _VerifikasiOTPScreenState();
}

class _VerifikasiOTPScreenState extends State<VerifikasiOTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _otpValid = false; // Untuk mengontrol validitas OTP
  bool _messageVisible = true; // Mengontrol visibilitas pesan

  @override
  void initState() {
    super.initState();
    _showTemporaryMessage();
  }

  Future<void> _showTemporaryMessage() async {
    await Future.delayed(const Duration(seconds: 3)); // Tampilkan pesan selama 3 detik
    setState(() {
      _messageVisible = false; // Sembunyikan pesan setelah 3 detik
    });
  }

  Future<void> _resendOTP() async {
    // Logika untuk mengirim ulang OTP
    String otp = generateOTP(6);

    await FirebaseFirestore.instance.collection('otps').doc(widget.userId).set({
      'email': widget.email,
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final smtpServer = SmtpServer(
      'smtp.mailersend.net',
      port: 587,
      username: 'MS_8WNEtY@trial-0p7kx4xejqmg9yjr.mlsender.net',
      password: 'Zo2fPMyr8J2Akpx6',
    );

    final message = Message()
      ..from = const Address('MS_8WNEtY@trial-0p7kx4xejqmg9yjr.mlsender.net', 'Your App Name')
      ..recipients.add(widget.email)
      ..subject = 'Your OTP Code'
      ..text = 'Your OTP code is $otp';

    try {
      await send(message, smtpServer);
      print('OTP sent successfully');
      _showResendPopup();
    } on MailerException catch (e) {
      print('Failed to send OTP: $e');
    }
  }

  Future<void> _showResendPopup() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Kode telah dikirim ulang.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String generateOTP(int length) {
    final Random random = Random();
    const String digits = '0123456789';
    return List.generate(length, (index) => digits[random.nextInt(digits.length)]).join();
  }

  Future<bool> verifyOTP(String enteredOtp) async {
    DocumentSnapshot otpDoc = await FirebaseFirestore.instance.collection('otps').doc(widget.userId).get();

    if (otpDoc.exists) {
      String storedOtp = otpDoc['otp'];
      if (storedOtp == enteredOtp) {
        await FirebaseFirestore.instance.collection('otps').doc(widget.userId).delete();
        return true;
      }
    }
    return false;
  }

  void _onVerifikasiPressed() async {
  if (await verifyOTP(_otpController.text)) {
    await _updateEmailInFirestore(); // Panggil metode untuk mengupdate email
    _showSuccessPopup();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP tidak valid')),
    );
  }
}

Future<void> _updateEmailInFirestore() async {
  try {
    // Update email di Firestore untuk user yang sedang login
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'email': widget.email,
    });
    print('Email berhasil diganti di Firestore');
  } catch (e) {
    print('Gagal mengganti email di Firestore: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mengganti email di Firestore: $e')),
    );
  }
}


  Future<void> _showSuccessPopup() async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/ic_outline-message.svg', // Menggunakan ikon SVG
              color: const Color(0xFF62E703),
              height: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Email Berhasil Diganti!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800, // Nunito Extra Bold
                fontSize: 20,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BottomNavigation(selectedIndex: 3)), // Navigate to ProfilePage
              );
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60), // Mengatur jarak dari atas
            SvgPicture.asset(
              'assets/ic_outline-message.svg', // Menggunakan ikon SVG
              color: const Color(0xFF62E703),
              height: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Masukkan Kode Verifikasi',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800, // Nunito Extra Bold
                fontSize: 25,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 10),
            Visibility(
              visible: _messageVisible, // Hanya terlihat selama beberapa detik
              child: const Text(
                'Kode verifikasi telah dikirim ke Email kamu.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700, // Nunito Bold
                  fontSize: 14,
                  color: Color(0xFF5F5F5F),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              onChanged: (value) {
                setState(() {
                  _otpValid = value.length == 6; // Verifikasi panjang OTP
                });
              },
              decoration: InputDecoration(
                hintText: 'Masukkan 6 digit kode verifikasi',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F5F5F),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _resendOTP,
              child: const Text.rich(
                TextSpan(
                  text: 'Tidak menerima kode? ',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700, // Nunito Bold
                    fontSize: 14,
                    color: Color(0xFF5F5F5F),
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Kirim ulang',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700, // Nunito Bold
                        fontSize: 14,
                        color: Color(0xFF319F43),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _otpValid ? _onVerifikasiPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _otpValid ? const Color(0xFF62E703) : const Color(0xFF707070),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verifikasi',
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