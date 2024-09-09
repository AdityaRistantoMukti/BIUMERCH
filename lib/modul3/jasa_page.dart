import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/modul3/category_page.dart';
import 'package:biumerch_mobile_app/modul3/landing_page.dart';
import 'package:biumerch_mobile_app/modul4/page_payment/history_page.dart';
import 'package:biumerch_mobile_app/modul3/perlengkapan_page.dart';
import 'package:biumerch_mobile_app/modul2/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:biumerch_mobile_app/modul3/product.dart'; // Import ProductCard
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() => runApp(HalamanJasaApp());

class HalamanJasaApp extends StatelessWidget {
  const HalamanJasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jasa',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HalamanJasa(),
    );
  }
}

class HalamanJasa extends StatefulWidget {
  const HalamanJasa({super.key});

  @override
  _HalamanJasaState createState() => _HalamanJasaState();
}

class _HalamanJasaState extends State<HalamanJasa> {
  final int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; // Semua produk dari Firebase
  List<Product> _filteredProducts = [];
  bool _isLoading = true; // Flag untuk mengecek apakah sedang loading data
  bool _isSearching = false; // Flag untuk mengecek apakah pencarian aktif

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Ambil produk dari Firebase saat inisialisasi
  }

  void _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: 'Jasa') // Filter berdasarkan kategori
          .get();

      final List<Product> products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      setState(() {
        _allProducts = products; // Simpan semua produk ke _allProducts
        _filteredProducts = products; // Menampilkan produk dengan kategori "Jasa"
        _isLoading = false; // Data sudah diambil, set _isLoading ke false
      });
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        _isLoading = false; // Jika ada error, tetap set _isLoading ke false
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
      _isSearching = true; // Aktifkan flag pencarian
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jasa',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,      
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : Center(
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[200],
                    height: 1.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 30,
                              ),
                              hintText: 'Butuh jasa apa?',
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
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _isSearching ? 'Jasa Tidak Ditemukan' : 'Jasa Tidak tersedia',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Menambahkan padding
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height * 0.80),
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductCard(product: product); // Menggunakan ProductCard
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
