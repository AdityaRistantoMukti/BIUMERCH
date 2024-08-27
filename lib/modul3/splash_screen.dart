import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    var duration = const Duration(seconds: 3);
    await Future.delayed(duration);  // Pause for the duration
    if (mounted) {  // Ensure widget is still in the tree
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BottomNavigation()),  // Directly navigate to BottomNavigation
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', 
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/logos/logo_baru.png', 
              width: 150,
              height: 150,
            ),
          ),
        ],
      ),
    );
  }
}
