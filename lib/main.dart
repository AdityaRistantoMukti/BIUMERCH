import 'package:biumerch_mobile_app/modul1/ForgotPasswordPage.dart';
import 'package:biumerch_mobile_app/modul1/RegisterPage.dart';
import 'package:biumerch_mobile_app/modul1/VerificationPage.dart';
import 'package:biumerch_mobile_app/modul1/VerificationSuccessPage.dart';
import 'package:biumerch_mobile_app/modul1/WelcomePage.dart';
import 'package:biumerch_mobile_app/modul2/chat_page.dart';
import 'package:biumerch_mobile_app/formatif.dart';
import 'package:biumerch_mobile_app/modul1/login.dart';
import 'package:biumerch_mobile_app/modul2/penjual_toko.dart';
import 'package:biumerch_mobile_app/modul2/profile_page.dart';
import 'package:biumerch_mobile_app/modul2/tokobaru.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modul3/splash_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
   // Mengunci orientasi ke portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',  
      debugShowCheckedModeBanner: false,       
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // Tampilkan SplashScreen saat aplikasi diluncurkan
      routes: {
        '/welcome': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/profile': (context) => const ProfilePage(),
        '/chatpage': (context) => const ChatPage(),        
        '/sellerProfile': (context) => SellerProfileScreen(storeId: ''), // Sesuaikan dengan logika  
        '/formatif': (context) => const FormatifPage(),      
        '/tokobaru': (context) => const TokoBaruPage(), // Tambahkan route untuk TokoBaruPage
        '/verification': (context) => VerificationPage(
              verificationId: '', // Placeholder, will be set during navigation
              phone: '', // Placeholder, will be set during navigation
            ),
        '/verification_success': (context) => VerificationSuccessPage(),        
        '/forgot_password': (context) =>
            ForgotPasswordPage(), // Tambahkan route untuk halaman lupa password
      },  
      
    );
  }
}
