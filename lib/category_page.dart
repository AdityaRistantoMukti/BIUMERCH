import 'package:biumerch_mobile_app/halaman_keranjang.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/jasa_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/makanan_minuman.dart';
import 'package:biumerch_mobile_app/perlengkapan_page.dart';
import 'package:biumerch_mobile_app/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategoryPage extends StatelessWidget {
  @override 
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LandingPage(),
        ));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(          
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LandingPage()),
              );
            },
          ),
          title: Text(
            'Kategori',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
             Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Mau cari apa?',
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0), // Adjust padding to control spacing
                      child: Icon(
                        Icons.search,
                        color: Colors.grey[800],  // Make the icon color more prominent
                        size: 28.0,  // Increase the size of the icon
                      ),
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,  // Color of the hint text
                      height: 1.5,  // Adjust the line height (this affects the vertical positioning of the hint text)
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0), // Adjust vertical padding for hint text margin
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Category Wrap
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: categories.map((category) {
                    return Container(
                      width: MediaQuery.of(context).size.width / 4 - 20,
                      child: _buildCategoryCard(
                        svgPath: category['svgPath'],
                        svgWidth: category['svgWidth'] ?? 40.0,
                        svgHeight: category['svgHeight'] ?? 40.0,
                        containerWidth: category['containerWidth'] ?? 80.0,
                        containerHeight: category['containerHeight'] ?? 80.0,
                        title: category['title'],
                        onTap: () {
                          _navigateToPage(context, category['title']);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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
                color: Colors.grey[800],
              ),
              label: 'Kategori',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/NavigationBar/riwayat.png',
                width: 24,
                height: 24,
                color: Colors.grey[400],
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
          currentIndex: 1,
          selectedItemColor: Colors.grey[800],
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) {
                switch (index) {
                  case 0:
                    return LandingPage();
                  case 1:
                    return CategoryPage();
                  case 2:
                    return HistoryPage();
                  case 3:
                    return ProfilePage();
                  default:
                    return LandingPage();
                }
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String svgPath,
    required double svgWidth,
    required double svgHeight,
    required double containerWidth,
    required double containerHeight,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Align text to the center
        children: [
          Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              color: Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Center(
              child: SizedBox(
                width: svgWidth,
                height: svgHeight,
                child: SvgPicture.asset(
                  svgPath,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center, // Align text to the center
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, String title) {
    Widget page;

    switch (title) {
      case 'Makanan & Minuman':
        page = HalamanMakananMinuman();
        break;
      case 'Jasa':
        page = HalamanJasa();
        break;
      case 'Perlengkapan':
        page = HalamanPerlengkapan();
        break;              
      default:
        page = LandingPage();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

final List<Map<String, dynamic>> categories = [
  {
    'svgPath': 'assets/icons/Kategori/makanan&minuman.svg',
    'title': 'Makanan & Minuman',
    'svgWidth': 35.0,
    'svgHeight': 35.0,
    'containerWidth': 80.0,
    'containerHeight': 80.0,
  },
  {
    'svgPath': 'assets/icons/Kategori/jasa.svg',
    'title': 'Jasa',
    'svgWidth': 40.0,
    'svgHeight': 40.0,
    'containerWidth': 80.0,
    'containerHeight': 80.0,
  },
  {
    'svgPath': 'assets/icons/Kategori/perlengkapan.svg',
    'title': 'Perlengkapan',
    'svgWidth': 30.0,
    'svgHeight': 30.0,
    'containerWidth': 80.0,
    'containerHeight': 80.0,
  },
];
