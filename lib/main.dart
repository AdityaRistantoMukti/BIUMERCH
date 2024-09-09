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
import 'package:biumerch_mobile_app/modul4/page_payment/history_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modul3/splash_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Inisialisasi plugin notifikasi lokal
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler untuk pesan FCM di background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Menambahkan handler untuk pesan FCM di background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi pengaturan Android
  var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Inisialisasi plugin notifikasi
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Membuat channel notifikasi untuk Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_notifications', // ID channel harus unik di seluruh aplikasi
    'Chat Notifications', // Nama channel untuk user
    description: 'Notifikasi untuk pesan chat baru dari pembeli atau penjual.', // Deskripsi channel
    importance: Importance.high,
  );

  // Mendaftarkan channel di Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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
        '/sellerProfile': (context) => const SellerProfileScreen(storeId: ''), // Sesuaikan dengan logika
        '/formatif': (context) => const FormatifPage(),
        '/tokobaru': (context) => const TokoBaruPage(), // Tambahkan route untuk TokoBaruPage
        '/riwayat': (context) =>  HistoryPage(),
        '/verification': (context) => VerificationPage(
              verificationId: '', // Placeholder, will be set during navigation
              phone: '', verification: '', email: '', // Placeholder, will be set during navigation
            ),
        '/verification_success': (context) => VerificationSuccessPage(),
        '/forgot_password': (context) => ForgotPasswordPage(), // Tambahkan route untuk halaman lupa password
      },
    );
  }
}

// Fungsi untuk menangani pesan yang diterima saat aplikasi dibuka atau di background
void _listenToMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showNotification(
        message.notification!.title ?? 'Pesan Baru',
        message.notification!.body ?? 'Anda menerima pesan baru.',
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    // Navigasi ke halaman tertentu jika diperlukan
  });
}

// Fungsi untuk menampilkan notifikasi
Future<void> _showNotification(String title, String body) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'chat_notifications',
    'Chat Notifications',
    channelDescription: 'Notifikasi untuk pesan chat baru dari pembeli atau penjual.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'Default_Sound',
  );
}
