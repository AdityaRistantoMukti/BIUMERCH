// Inisialisasi plugin notifikasi lokal
import 'dart:async';
import '/bottom_navigation.dart';
import '/firebase_options.dart';
import '/formatif.dart';
import '/modul1/ForgotPasswordPage.dart';
import '/modul1/RegisterPage.dart';
import '/modul1/VerificationPage.dart';
import '/modul1/VerificationSuccessPage.dart';
import '/modul1/WelcomePage.dart';
import '/modul1/login.dart';
import '/modul2/chat_page.dart';
import '/modul2/features/tarik_saldo/providers/withdrawal_pembeli_provider.dart';
import '/modul2/features/tarik_saldo/providers/withdrawal_provider.dart';
import '/modul2/features/tarik_saldo/views/pembeli/tarik_saldo/tarik_saldo_pembeli_screen.dart';
import '/modul2/features/tarik_saldo/views/pembeli/tarik_saldo_riwayat/tarik_saldo_history_pembeli_view.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/tarik_saldo_screen.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo_riwayat/tarik_saldo_history_view.dart';
import '/modul2/penjual_toko.dart';
import '/modul2/tokobaru.dart';
import '/modul3/listChatPembeli.dart';
import '/modul3/splash_screen.dart';
import '/modul4/history/history_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler untuk pesan FCM di background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    initDeepLinkListener(); // Panggil fungsi listener deep link
    _listenToMessages(); // Mulai mendengarkan pesan FCM
  }

  // Fungsi untuk mendengarkan deep link
  void initDeepLinkListener() async {
  try {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        if (uri.host == "success") {
          // Update captcha verification status
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCaptchaVerified', true);

          // Navigasi ke halaman sukses (landing page)
          Navigator.pushReplacementNamed(context, '/landing_page');
        } else if (uri.host == "failed") {
          // Jika gagal, arahkan ke halaman login atau berikan notifikasi
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCaptchaVerified', false);

          // Navigasi ke halaman login atau tampilkan pesan error
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }, onError: (err) {
      // Handle error deep link jika ada
      print("Deep link error: $err");
    });
  } on PlatformException catch (e) {
    print("Failed to get deep link: $e");
  }
}

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Fungsi untuk mendengarkan pesan FCM
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
      if (message.data['route'] != null) {
        Navigator.pushNamed(context, message.data['route']);
      }
    });
  }

  // Fungsi untuk menampilkan notifikasi lokal
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
        '/login': (context) => const LoginPage(),
        '/register': (context) => RegisterPage(),
        '/profile': (context) => BottomNavigation(selectedIndex: 3,),
        '/chatpage': (context) => const ChatPage(),
        '/sellerProfile': (context) => const SellerProfileScreen(storeId: ''),
        '/formatif': (context) => const FormatifPage(),
        '/tokobaru': (context) => const TokoBaruPage(),
        '/listChatPembeli': (context) => const ListChatPembeli(),
        '/riwayat': (context) => HistoryPage(),
        '/verification': (context) => VerificationPage(
              verificationId: '', // Placeholder, will be set during navigation
              phone: '', // Placeholder, will be set during navigation
            ),
        '/verification_success': (context) => VerificationSuccessPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/landing_page': (context) => BottomNavigation(), // Route untuk LandingPage
        '/tarik_saldo': (context) => const TarikSaldoScreen(),
        '/tarik_saldo_pembeli': (context) => const TarikSaldoPembeliScreen(),
        '/tarik_saldo_riwayat': (context) => const TarikSaldoHistoryView(),
        '/tarik_saldo_riwayat_pembeli': (context) => const TarikSaldoHistoryPembeliView(),
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 try {
    // Attempt to initialize 'id_ID' locale formatting
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    print('Error loading locale data for id_ID: $e');
    // Fallback to default locale or continue without it
    await initializeDateFormatting(); // Initializes default locale data
  }  // Inisialisasi Firebase Analytics
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
    description: 'Notifikasi untuk pesan chat baru dari pembeli atau penjual.',
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


  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()), // Menambahkan WithdrawalProvider
        ChangeNotifierProvider(create: (_) => WithdrawalPembeliProvider()), // Menambahkan WithdrawalProvider
      ],
      child: const MyApp(),
    ),);
}