import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/modul3/category_page.dart';
import 'package:biumerch_mobile_app/modul3/landing_page.dart';
import 'package:biumerch_mobile_app/modul4/page_payment/history_page.dart';
import 'package:biumerch_mobile_app/modul2/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:biumerch_mobile_app/modul3/product.dart'; // Import Product dan ProductCard
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() => runApp(MakananMinumanApp());

class MakananMinumanApp extends StatelessWidget {
  const MakananMinumanApp({super.key});

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
  const HalamanMakananMinuman({super.key});

  @override
  _HalamanMakananMinumanState createState() => _HalamanMakananMinumanState();
}

class _HalamanMakananMinumanState extends State<HalamanMakananMinuman> {
  final int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; // Menyimpan semua produk yang diambil dari Firebase
  List<Product> _filteredProducts = [];
  bool _isLoading = true; // Menandakan apakah data sedang di-fetch

  final List<Widget> _widgetOptions = <Widget>[
    LandingPage(),
    CategoryPage(),
    HistoryPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    setState(() {
      _isLoading = true; // Set _isLoading menjadi true saat mulai fetch data
    });

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
        _isLoading = false; // Set _isLoading menjadi false saat data sudah diambil
      });

      print("Total products fetched: ${_allProducts.length}");
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        _isLoading = false; // Set _isLoading menjadi false jika terjadi error
      });
    }
  }

  void _onItemTapped(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = BottomNavigation();
        break;
      case 1:
        page = BottomNavigation(selectedIndex: 1);
        break;
      case 2:
        page = BottomNavigation(selectedIndex: 2);
        break;
      case 3:
        page = BottomNavigation(selectedIndex: 3);
        break;
      default:
        page = BottomNavigation();
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
        transitionDuration: const Duration(milliseconds: 10), // Durasi transisi yang lebih panjang
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
        title: const Text(
          'Makanan & Minuman',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading // Periksa apakah sedang loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Warna loader hijau
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 30),
                      hintText: 'Pengen makan apa?',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _filterProducts,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _allProducts.isEmpty
                                  ? 'Makanan Tidak Tersedia'
                                  : 'Makanan Tidak Ditemukan',
                              style: const TextStyle(
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
                              childAspectRatio: MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height * 0.80),
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
