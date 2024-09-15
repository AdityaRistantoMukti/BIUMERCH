import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/modul3/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ForgotPasswordPage.dart';
import 'VerificationPage.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError; // Variabel untuk menyimpan pesan error email
  String? _passwordError; // Variabel untuk menyimpan pesan error password
  bool _isLoading = false; // Tambahkan variabel ini untuk mengontrol loading
  bool _isPasswordVisible = false; // Menambah variabel untuk visibilitas password
  void _login() async {
    setState(() {
      _isLoading = true; // Set loading saat proses login dimulai
      _emailError = null; // Reset error saat login dimulai
      _passwordError = null; // Reset error saat login dimulai
    });

    String emailOrPhone = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();

    if (emailOrPhone.contains('@')) {
      try {
        // Mencoba login menggunakan email dan password
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailOrPhone,
          password: password,
        );

        User? user = userCredential.user;

        // Mengecek apakah email sudah diverifikasi
        if (user != null && user.emailVerified) {
          // Email sudah diverifikasi, simpan status login dan navigasi ke halaman utama
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavigation(),
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          // Jika email belum diverifikasi, tampilkan pesan dan logout sementara
          setState(() {
            _emailError = 'Akun belum terverifikasi. Cek email Anda untuk verifikasi.';
          });

          // Mengirim ulang email verifikasi
          if (user != null) {
            await user.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Email verifikasi telah dikirim ulang. Silakan cek kotak masuk Anda.'),
              ),
            );
          }

          // Logout pengguna sementara
          await _auth.signOut();
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase errors dan terjemahkan ke bahasa Indonesia
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _emailError = 'Email tidak terdaftar.';
              break;
            case 'wrong-password':
              _passwordError = 'Password salah.';
              break;
            case 'invalid-email':
              _emailError = 'Format email salah.';
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login gagal: ${e.message}')),
              );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Set loading selesai
        });
      }
    } else {
      // Jika input bukan email, gunakan login dengan nomor telepon
      _loginWithPhone(emailOrPhone, password);
    }
  }

  Future<void> _loginWithPhone(String phoneNumber, String password) async {
    try {
      final confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(
            verificationId: confirmationResult.verificationId,
            phone: phoneNumber,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: ${e.toString()}')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true; // Mulai loading untuk satu loading state
    });

    try {
      // Sign out from any previous Google account (ensures account selection on next sign-in)
      await _googleSignIn.signOut();
      // Attempt to sign in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In dibatalkan')),
        );
        return;
      }

      // Authenticate with Firebase
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Simpan status login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Navigate to landing page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In gagal: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In gagal: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hentikan loading
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/BGLogin.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 323.0), // Vertical spacing
                    Text(
                      'Hai, Sob!\nBalik lagi nih! \nYuk, lanjut belanja!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 25.0,
                        fontWeight: FontWeight.w800,
                        height: 34.1 / 25, // Line-height / font-size
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.0), // Vertical spacing
                    Text(
                      'Masuk ke akunmu yuk!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        height: 19.07 / 14, // Line-height / font-size
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 48.0), // Vertical spacing
                    TextField(
                      controller: _emailOrPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Masukan email/No Telepon',
                        labelStyle: TextStyle(
                          color: Color(0xFF0B4D3B),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0), // Vertical spacing
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Masukan password',
                        labelStyle: TextStyle(
                          color: Color(0xFF0B4D3B),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible =
                                  !_isPasswordVisible; // Ubah visibilitas password
                            });
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: Text(
                          'Lupa password?',
                          style: TextStyle(
                            color: Color(0xFF319F43),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0), // Vertical spacing
                    SizedBox(
                      width: double.infinity,
                      height: 52.0,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _login, // Disable the button when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF62E703),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Masuk',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28.0,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16.0), // Vertical spacing
                    Text(
                      'atau',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 16.0), // Vertical spacing
                    SizedBox(
                      width: double.infinity,
                      height: 52.0,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : _signInWithGoogle, // Disable the button when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            side: BorderSide(color: Colors.black),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/google_logo2.png',
                          height: 24.0,
                        ),
                        label: _isLoading
                            ? CircularProgressIndicator()
                            : Text(
                                'Masuk dengan Google',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.0,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 120.0), // Vertical spacing
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}