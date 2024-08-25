import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
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
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(),
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
      }
    } else {
      _loginWithPhone(emailOrPhone, password);
    }
  }

  void _loginWithPhone(String phoneNumber, String password) async {
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
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Attempt to sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In was cancelled')),
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
        // Check if user is new
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // If the user is new, save their information to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'username': user.displayName ?? 'Anonymous',
            'createdAt': FieldValue.serverTimestamp(),
            'balance': 0, // Set initial balance to 0
            'idUser': user.uid, // Set idUser to the same as the document ID
            'phoneNumber': '', // Set phoneNumber to empty string
            'profilePicture': '', // Set profilePicture to empty string
          });

          // Create the clicked_products sub-collection
          String productId = 'exampleProductId';
          String category = 'exampleCategory';
          int initialCount = 1;

          await _firestore.collection('users').doc(user.uid)
              .collection('clicked_products').doc(productId).set({
            'category': category,
            'timestamp': FieldValue.serverTimestamp(),
            'count': initialCount,
          });

          print("User and clicked_products collection created for user ${user.uid}");
        }

        // Save login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Navigate to landing page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(),
          ),
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
                    SizedBox(height: 20.0), // Vertical spacing
                    Text(
                      'Masuk ke akunmu yuk!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5F5F5F),
                      ),
                    ),
                    SizedBox(height: 20.0), // Vertical spacing
                    TextField(
                      controller: _emailOrPhoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'Masukkan email atau nomor telepon',
                        labelStyle: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B4D3B),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'Masukkan password',
                        labelStyle: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B4D3B),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: Text(
                          'Lupa password?',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Color(0xFF319F43),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF62E703),
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        child: Text('Masuk'),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          child: Divider(color: Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          width: 100,
                          child: Divider(color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(color: Colors.grey),
                          ),
                          textStyle: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset('assets/google_logo.png', height: 24.0),
                            SizedBox(width: 10.0),
                            Text('Masuk menggunakan Google',
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
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
