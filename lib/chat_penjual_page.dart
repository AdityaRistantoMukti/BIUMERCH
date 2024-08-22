import 'package:biumerch_mobile_app/category_page.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HalamanChatPenjual extends StatefulWidget {
  @override
  _HalamanChatPenjualState createState() => _HalamanChatPenjualState();
}

class _HalamanChatPenjualState extends State<HalamanChatPenjual> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoryPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman Chat Penjual'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Halaman Chat Penjual',
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
              color: _selectedIndex == 0 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/kategori.svg',
              width: 24,
              height: 24,
              color: _selectedIndex == 1 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/NavigationBar/riwayat.png',
              width: 24,
              height: 24,
              color: _selectedIndex == 2 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/profil.svg',
              width: 30,
              height: 30,
              color: _selectedIndex == 3 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey[800],
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
