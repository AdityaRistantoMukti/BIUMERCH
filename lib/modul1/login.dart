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
  bool _isLoading = false; // Tambahkan variabel ini untuk mengontrol loading

  void _login() async {
    setState(() {
      _isLoading = true; // Set loading saat proses login dimulai
    });

    String emailOrPhone = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();

    if (emailOrPhone.contains('@')) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailOrPhone,
          password: password,
        );

        // Save login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(),
          ),
          (Route<dynamic> route) => false, 
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Set loading selesai
        });
      }
    } else {
      _loginWithPhone(emailOrPhone, password);
    }
  }

  void _loginWithPhone(String phoneNumber, String password) async {
    setState(() {
      _isLoading = true; // Set loading saat proses login dimulai
    });

    try {
      final confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(
            verification: confirmationResult.verificationId,
            phone: phoneNumber,
            email: '',
            verificationId: '',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading selesai
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Sign out from any previous Google account (ensures account selection on next sign-in)
      await _googleSignIn.signOut();
      // Attempt to sign in with Google
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In was cancelled')),
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
        // Cek apakah pengguna baru
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // Jika pengguna baru, simpan informasi mereka ke Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'username': user.displayName ?? 'Anonymous',
            'createdAt': FieldValue.serverTimestamp(),
            'balance': 0, // Set initial balance to 0
            'idUser': user.uid, // Set idUser to the same as the document ID
            'phone': '', // Set phoneNumber to empty string
            'profilePicture': '', // Set profilePicture to empty string
          });

          // Daftar kategori yang akan dibuat dalam sub-koleksi 'categoryVisits'
          List<String> categories = ['Makanan & Minuman', 'Jasa', 'Elektronik', 'Perlengkapan'];

          await _firestore.collection('users').doc(user.uid)
              .collection('categoryVisits')
              .get()
              .then((snapshot) async {
            if (snapshot.docs.isEmpty) {
              // Jika sub-koleksi 'categoryVisits' kosong, tambahkan dokumen dengan nama kategori
              for (String category in categories) {
                await _firestore.collection('users').doc(user.uid)
                    .collection('categoryVisits').doc(category).set({
                  'category': category,
                  'visitCount': 0,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
              print("Category visits collection created with initial categories for user ${user.uid}");
            } else {
              print("Category visits collection already exists for user ${user.uid}");
            }
          });
        }

        // Save login status
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
        SnackBar(content: Text('Google Sign-In failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
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
            decoration: const BoxDecoration(
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
                    const SizedBox(height: 323.0), // Vertical spacing
                    const Text(
                      'Hai, Selamat \nDatang Kembali!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 25.0,
                        fontWeight: FontWeight.w800,
                        height: 34.1 / 25, // Line-height / font-size
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20.0), // Vertical spacing
                    const Text(
                      'Masuk ke akunmu yuk!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5F5F5F),
                      ),
                    ),
                    const SizedBox(height: 20.0), // Vertical spacing
                    TextField(
                      controller: _emailOrPhoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'Masukkan email atau nomor telepon',
                        labelStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B4D3B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'Masukkan password',
                        labelStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B4D3B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Color(0xFF319F43),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login, // Disable button while loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : const Color(0xFF62E703), // Ubah warna tombol saat loading
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle, // Disable button while loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : const Color(0xFF62E703), // Ubah warna tombol saat loading
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Masuk dengan Google'),
                      ),
                    ),
                    const SizedBox(height: 20.0),
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
