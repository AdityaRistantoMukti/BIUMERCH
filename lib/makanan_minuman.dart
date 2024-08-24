import 'package:biumerch_mobile_app/category_page.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:biumerch_mobile_app/product.dart'; // Import Product dan ProductCard
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() => runApp(MakananMinumanApp());

class MakananMinumanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makanan & Minuman',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HalamanMakananMinuman(),
    );
  }
}

class HalamanMakananMinuman extends StatefulWidget {
  @override
  _HalamanMakananMinumanState createState() => _HalamanMakananMinumanState();
}

class _HalamanMakananMinumanState extends State<HalamanMakananMinuman> {
  int _selectedIndex = 0;
  TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; // Menyimpan semua produk yang diambil dari Firebase
  List<Product> _filteredProducts = [];

  final List<Widget> _widgetOptions = <Widget>[
    LandingPage(),
    CategoryPage(),
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

    void _fetchProducts() async {
      try {
        // Ambil produk dari Firebase yang hanya memiliki kategori "Makanan & Minuman"
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: 'Makanan & Minuman')
            .get();
        
        final List<Product> products = snapshot.docs.map((doc) {
          print("Document data: ${doc.data()}"); // Print data yang diambil untuk debugging
          return Product.fromFirestore(doc);
        }).toList();

        setState(() {
          _allProducts = products;
          _filteredProducts = products;
        });
        
        print("Total products fetched: ${_allProducts.length}");
      } catch (e) {
        print("Error fetching products: $e");
      }
  }



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
        page = LandingPage();
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

  void _filterProducts(String query) {
    final List<Product> filteredProducts = _allProducts.where((product) {
      final productName = product.title.toLowerCase();
      final input = query.toLowerCase();
      return productName.contains(input);
    }).toList();

    setState(() {
      _filteredProducts = filteredProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Makanan & Minuman',
          style: TextStyle(
            color: Colors.black, // Warna teks hitam
            fontWeight: FontWeight.bold, // Teks tebal
          ),
        ),
        centerTitle: true, // Pusatkan teks di AppBar        
        elevation: 0, // Menghilangkan bayangan AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Garis di atas UI search
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, size: 30),
                hintText: 'Pengen makan apa?',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFFF3F3F3), // Background warna search
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterProducts,
            ),
            SizedBox(height: 10),
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        _allProducts.isEmpty
                            ? 'Makanan Tidak Tersedia'
                            : 'Makanan Tidak Ditemukan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        childAspectRatio: 0.63,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ProductCard(product: product);
                      },
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