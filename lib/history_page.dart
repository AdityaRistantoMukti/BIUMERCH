import 'package:biumerch_mobile_app/category_page.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    Widget page;

    switch (index) {
      case 0:
        page = LandingPage();
        break;
      case 1:
        page = CategoryPage();
        break;
      case 2:
        page = HistoryPage();
        break;
      case 3:
        page = ProfilePage();
        break;
      default:
        return;
    }

     Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final opacityAnimation = animation.drive(
            CurveTween(curve: Curves.easeInOut), // Menggunakan kurva yang lebih halus
          ).drive(
            Tween<double>(begin: 0.0, end: 1.0),
          );
          return FadeTransition(opacity: opacityAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 10), // Durasi transisi yang lebih panjang
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Page'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Riwayat Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/beranda.svg',
              width: 24,
              height: 24,
              color: Colors.grey[400],
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/kategori.svg',
              width: 24,
              height: 24,
              color: Colors.grey[400],
            ),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/NavigationBar/riwayat.png',
              width: 24,
              height: 24,
              color: Colors.grey[800],
            ),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/profil.svg',
              width: 30,
              height: 30,
              color: Colors.grey[400],
            ),
            label: 'Profil',
          ),
        ],
        currentIndex: 2,
        selectedItemColor: Colors.grey[800],
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
