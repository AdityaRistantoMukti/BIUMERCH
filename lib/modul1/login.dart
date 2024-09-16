import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ForgotPasswordPage.dart';
import 'VerificationPage.dart';
import 'RecaptchaScreen.dart'; // Import the reCAPTCHA screen

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
  bool _isLoading = false; // Kontrol loading state
  bool _isPasswordVisible = false; // Kontrol visibilitas password
  bool _isCaptchaVerified = false; // Tambahkan ini untuk melacak verifikasi captcha

  // Fungsi login dengan email dan password
  void _login() async {
    setState(() {
      _isLoading = true; // Mulai loading
      _emailError = null; // Reset error
      _passwordError = null; // Reset error
    });

    String emailOrPhone = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();

    // Validasi form input email dan password
    if (emailOrPhone.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong.';
        _isLoading = false;
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong.';
        _isLoading = false;
      });
      return;
    }

    // Langkah login
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
          // Lanjutkan ke reCAPTCHA
          final recaptchaResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecaptchaHandler(
                onVerified: (String result) {
                  return result;
                },
              ),
            ),
          );

          // Jika reCAPTCHA berhasil
          if (recaptchaResult == 'success') {
            setState(() {
              _isCaptchaVerified = true; // Tandai verifikasi captcha berhasil
            });

            // Simpan status login dan navigasi ke halaman utama
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
            setState(() {
              _isCaptchaVerified = false; // Captcha gagal diverifikasi
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verifikasi reCAPTCHA gagal. Silakan coba lagi.')),
            );
          }
        } else {
          setState(() {
            _emailError = 'Akun belum terverifikasi. Cek email Anda untuk verifikasi.';
          });

          if (user != null) {
            await user.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email verifikasi telah dikirim ulang. Silakan cek kotak masuk Anda.'),
              ),
            );
          }

          await _auth.signOut();
        }
      } on FirebaseAuthException catch (e) {
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
          _isLoading = false; // Stop loading
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
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true; // Mulai loading untuk satu loading state
    });

    try {
      await _googleSignIn.signOut();

      // Memastikan pengguna memilih akun Google terlebih dahulu
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In dibatalkan')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Lanjutkan proses login dengan Google jika pengguna memilih akun
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Lanjutkan ke reCAPTCHA setelah akun dipilih
        final recaptchaResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecaptchaHandler(
              onVerified: (String result) {
                return result;
              },
            ),
          ),
        );

        // Jika reCAPTCHA berhasil
        if (recaptchaResult == 'success') {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verifikasi reCAPTCHA gagal. Silakan coba lagi.')),
          );
        }
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
        _isLoading = false; // Stop loading
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
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/BGLogin.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Spacer(), // Menambah Spacer untuk membuat konten fleksibel di tengah
                            SizedBox(height: 140.0), // Vertical spacing
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
                                errorText: _emailError, // Tampilkan error jika ada
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
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                errorText: _passwordError, // Tampilkan error jika ada
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
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF62E703),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0), // Vertical spacing
                            SizedBox(
                              width: double.infinity,
                              height: 52.0,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
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
                                label: Text(
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
                            Spacer(), // Spacer di bagian bawah untuk mendorong konten ke tengah
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) // Widget loading state
            Positioned.fill(
              child: Stack(
                children: <Widget>[
                  ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.5)),
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
