import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationPage2 extends StatefulWidget {
  final String verificationId;
  final String phone;

  VerificationPage2({required this.verificationId, required this.phone});

  @override
  _VerificationPage2State createState() => _VerificationPage2State();
}

class _VerificationPage2State extends State<VerificationPage2> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Save login status
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Navigate to BottomNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigation(), // Menampilkan tab default
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Masukkan Kode OTP',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 25.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Kode OTP telah dikirim ke nomor ${widget.phone}.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Kode OTP',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Text('Verifikasi'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
