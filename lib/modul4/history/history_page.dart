import 'package:biumerch_mobile_app/modul1/WelcomePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk QuerySnapshot
import 'dart:async'; // Untuk Timer
import 'package:shared_preferences/shared_preferences.dart'; // Untuk verifikasi CAPTCHA
import 'order_list.dart';
import 'order_service.dart';


class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Stream<List<QuerySnapshot>>? _combinedStream;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _combinedStream = OrderService().getCombinedStream(user.uid);
    }
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Fungsi untuk memeriksa apakah captcha sudah diverifikasi
  Future<bool> _isCaptchaVerified() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isCaptchaVerified') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isCaptchaVerified(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isCaptchaVerified = snapshot.data ?? false;
        User? user = FirebaseAuth.instance.currentUser;

        // Jika user belum login atau belum verifikasi captcha, tampilkan tombol untuk login
        if (user == null || !isCaptchaVerified) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomePage()), // Ganti dengan halaman login Anda
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login untuk melihat pesanan Anda',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Pesanan Saya",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            bottom: _buildTabBar(),
          ),
          body: _combinedStream == null
              ? const Center(child: CircularProgressIndicator())
              : OrderList(combinedStream: _combinedStream!, tabController: _tabController!),
        );
      },
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(50),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        isScrollable: true,
        tabs: [
          Tab(text: "Belum Bayar"),
          Tab(text: "Dipersiapkan"),
          Tab(text: "Dikirim"),
          Tab(text: "Selesai"),
          Tab(text: "Dibatalkan"),
        ],
      ),
    );
  }
}
