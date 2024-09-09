import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/modul3/category_page.dart';
import 'package:biumerch_mobile_app/modul3/landing_page.dart';
import 'package:biumerch_mobile_app/modul4/page_payment/history_page.dart';
import 'package:biumerch_mobile_app/modul2/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biumerch_mobile_app/modul3/product.dart'; // Import Product and ProductCard

class HalamanPerlengkapan extends StatefulWidget {
  const HalamanPerlengkapan({super.key});

  @override
  _HalamanPerlengkapanState createState() => _HalamanPerlengkapanState();
}

class _HalamanPerlengkapanState extends State<HalamanPerlengkapan> with WidgetsBindingObserver {
  final int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = []; // Menyimpan semua produk yang diambil dari Firebase
  List<Product> _filteredProducts = [];
  bool _isLoading = true; // Flag untuk mengecek apakah data sedang dimuat
  bool _isSearching = false; // Flag untuk mengecek apakah pencarian aktif

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProducts(); // Ambil produk dari Firebase saat inisialisasi
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset the filtered products when returning to this screen
      _fetchProducts();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true; // Mulai proses loading
    });

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('category', whereIn: ['Perlengkapan', 'Elektronik'])
        .get();

    final List<Product> products = snapshot.docs.map((doc) {
      return Product.fromFirestore(doc);
    }).toList();

    setState(() {
      _allProducts = products; // Simpan semua produk ke _allProducts
      _filteredProducts = products; // Menampilkan produk dengan kategori "Perlengkapan" atau "Elektronik"
      _isLoading = false; // Selesai proses loading
      _isSearching = false; // Reset pencarian saat produk diambil
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perlengkapan & Elektronik',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
             decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 30,
                  ),
                  hintText: 'Nyari perlengkapan apa?',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterProducts,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading // Tampilkan loader saat data sedang diambil
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Warna loader hijau
                      ),
                    )
                  : _isSearching
                      ? _filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'Produk tidak ditemukan',
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
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height * 0.70),
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return ProductCard(product: product); // Gunakan ProductCard untuk menampilkan produk
                              },
                            )
                      : _allProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'Produk tidak tersedia',
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
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height * 0.80),
                              ),
                              itemCount: _allProducts.length,  // Use _allProducts instead of _filteredProducts here
                              itemBuilder: (context, index) {
                                final product = _allProducts[index];
                                return ProductCard(product: product); // Gunakan ProductCard untuk menampilkan produk
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
