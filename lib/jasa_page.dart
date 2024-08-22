import 'package:biumerch_mobile_app/category_page.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/perlengkapan_page.dart';
import 'package:biumerch_mobile_app/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:biumerch_mobile_app/product.dart'; // Import ProductCard
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() => runApp(HalamanJasaApp());

class HalamanJasaApp extends StatelessWidget {
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
  @override
  _HalamanJasaState createState() => _HalamanJasaState();
}

class _HalamanJasaState extends State<HalamanJasa> {
  int _selectedIndex = 0;
  TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; // Semua produk dari Firebase
  List<Product> _filteredProducts = [];
  bool _isSearching = false; // Flag untuk mengecek apakah pencarian aktif

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Ambil produk dari Firebase saat inisialisasi
  }

  void _fetchProducts() async {
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
    });
  }

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
        title: Text(
          'Jasa',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,      
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              height: 1.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          size: 30,
                        ),
                        hintText: 'Butuh jasa apa?',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFFF3F3F3),
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
                          style: TextStyle(
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
                          childAspectRatio: 0.62,
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
