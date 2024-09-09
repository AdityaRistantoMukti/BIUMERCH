import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email, required String verification, required String phone, required String verificationId});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _otpController = TextEditingController();
  bool _isResendButtonEnabled = true;
  String? _generatedOtp; // OTP yang dihasilkan

  @override
  void initState() {
    super.initState();
    _sendOtpToEmail(); // Kirim OTP saat halaman pertama kali dimuat
  }

  void _sendOtpToEmail() async {
    setState(() {
      _isResendButtonEnabled = false;
    });

    // Menghasilkan OTP secara acak
    _generatedOtp = _generateOtp();

    try {
      // Di sini Anda bisa menggunakan layanan email untuk mengirim OTP
      // Contoh sederhana menggunakan clipboard (untuk pengujian)
      Clipboard.setData(ClipboardData(text: _generateOtp()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP telah dikirim ke email: ${widget.email}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim OTP')),
      );
    } finally {
      setState(() {
        _isResendButtonEnabled = true;
      });
    }
  }

  String _generateOtp() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // Menghasilkan OTP 6 digit
    return otp.toString();
  }

  void _verifyOtp() {
    if (_otpController.text == _generatedOtp) {
      Navigator.pushReplacementNamed(context, '/verification-success');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP tidak valid')),
      );
    }
  }

  void _resendOtp() async {
    _sendOtpToEmail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'), // Gambar latar belakang
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/verifikasilogo.png', // Pastikan format gambar yang digunakan sesuai
                    height: 150.0,
                    width: 150.0,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Verifikasi OTP',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF62E703),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Kode OTP telah dikirim ke ${widget.email}',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tidak menerima OTP?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: _isResendButtonEnabled ? _resendOtp : null,
                        child: Text(
                          'Kirim Ulang',
                          style: TextStyle(
                            color: _isResendButtonEnabled
                                ? const Color(0xFF62E703)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                          0.8), // Transparansi untuk konten di atas gambar
                      border: Border.all(color: const Color(0xFF0B4D3B)),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            labelText: 'Masukkan kode OTP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF62E703),
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Verifikasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
