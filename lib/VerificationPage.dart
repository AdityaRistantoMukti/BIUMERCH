import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class VerificationPage extends StatefulWidget {
  final String verificationId;
  final String phone;

  VerificationPage({required this.verificationId, required this.phone});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _otpController = TextEditingController();
  bool _isResendButtonEnabled = true; // State untuk tombol kirim ulang

  void _verifyOtp() async {
    try {
      // Mendapatkan kredensial dengan OTP yang dimasukkan
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );

      // Menyelesaikan proses login menggunakan kredensial
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigasi ke halaman verifikasi sukses
      Navigator.pushReplacementNamed(context, '/verification-success');
    } catch (e) {
      // Tangani kesalahan jika verifikasi gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP tidak valid')),
      );
    }
  }

  void _resendOtp() async {
    setState(() {
      _isResendButtonEnabled = false;
    });

    // Mengirim ulang kode OTP
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim ulang kode OTP')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isResendButtonEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode OTP telah dikirim ulang')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                  SizedBox(height: 20.0),
                  Text(
                    'Verifikasi OTP',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF62E703),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Kode OTP telah dikirim ke ${widget.phone}',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tidak menerima OTP?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: _isResendButtonEnabled ? _resendOtp : null,
                        child: Text(
                          'Kirim Ulang',
                          style: TextStyle(
                            color: _isResendButtonEnabled
                                ? Color(0xFF62E703)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                          0.8), // Transparansi untuk konten di atas gambar
                      border: Border.all(color: Color(0xFF0B4D3B)),
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
                  SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF62E703),
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        textStyle: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text('Verifikasi'),
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
