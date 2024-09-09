import 'package:biumerch_mobile_app/modul4/page_payment/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'modul3/landing_page.dart';
import 'modul3/category_page.dart';
import 'modul2/profile_page.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;

  BottomNavigation({super.key, this.selectedIndex = 0}); // Default ke index 0

  // Daftar halaman yang akan ditampilkan saat berpindah
  final List<Widget> _pages = <Widget>[
    LandingPage(),          // Beranda
    CategoryPage(),         // Kategori
    HistoryPage(),          // Riwayat
    const ProfilePage(),          // Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[selectedIndex], // Menampilkan halaman sesuai dengan item yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/beranda.svg',
              width: 24,
              height: 24,
              color: selectedIndex == 0 ? Colors.black : Colors.grey[400],
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/kategori.svg',
              width: 24,
              height: 24,
              color: selectedIndex == 1 ? Colors.black : Colors.grey[400],
            ),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/NavigationBar/riwayat.png',
              width: 24,
              height: 24,
              color: selectedIndex == 2 ? Colors.black : Colors.grey[400],
            ),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/profil.svg',
              width: 30,
              height: 30,
              color: selectedIndex == 3 ? Colors.black : Colors.grey[400],
            ),
            label: 'Profil',
          ),
        ],
        currentIndex: selectedIndex, // Item yang dipilih saat ini
        selectedItemColor: Colors.black, // Warna item yang dipilih (hitam pekat)
        unselectedItemColor: Colors.grey[400], // Warna item yang tidak dipilih (abu-abu)
        showSelectedLabels: true, // Menampilkan label item yang dipilih
        showUnselectedLabels: true, // Menampilkan label item yang tidak dipilih
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BottomNavigation(selectedIndex: index),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final opacityAnimation = animation.drive(
                  CurveTween(curve: Curves.easeInOut), // Kurva transisi halus
                ).drive(
                  Tween<double>(begin: 0.0, end: 1.0),
                );
                return FadeTransition(opacity: opacityAnimation, child: child);
              },
              transitionDuration:
                  const Duration(milliseconds: 10), // Durasi transisi yang diinginkan
            ),
          );
        }, // Fungsi yang dipanggil saat item diklik
      ),
    );
  }
}
