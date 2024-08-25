import 'dart:async';
import 'package:biumerch_mobile_app/page_payment/cart.dart';
import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'banner_model.dart';
import 'banner_service.dart';
import 'product.dart';
import 'search_page.dart';
import 'package:biumerch_mobile_app/perlengkapan_page.dart';
import 'package:biumerch_mobile_app/makanan_minuman.dart';
import 'package:biumerch_mobile_app/jasa_page.dart';
import 'package:biumerch_mobile_app/category_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  late Timer _timer;
  late Future<List<BannerModel>> _bannersFuture;
  late Future<List<Product>> _productsFuture;
  late Future<List<Product>> _recommendedProductsFuture; // Tambahkan ini untuk rekomendasi
  String _searchQuery = '';
  String _username = ''; // Variabel untuk menyimpan username
  int _totalBanners = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _bannersFuture = BannerService().getBanners().then((banners) {
      setState(() {
        _totalBanners = banners.length;
      });
      return banners;
    });
    _productsFuture = fetchProducts();
    _recommendedProductsFuture = _getRecommendedProducts(); // Inisialisasi Future rekomendasi
     _loadUsername(); // Panggil fungsi untuk load username
  }

  Future<void> _loadUsername() async {
    String? username = await _fetchUsername(); // Tunggu hasil dari _fetchUsername
    setState(() {
      _username = username ?? ''; // Update state dengan username
    });
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final List<Product> products = await FirebaseFirestore.instance
          .collection('products')
          .where('rating', isEqualTo: '4.5')
          .get()
          .then((snapshot) {
        return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      });
      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Product>> _getRecommendedProducts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot clickedProductsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clicked_products')
          .orderBy('count', descending: true)
          .limit(10)
          .get();

      List<Product> recommendedProducts = [];
      for (var doc in clickedProductsSnapshot.docs) {
        String category = doc['category'];
        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: category)
            .limit(5)
            .get();
        recommendedProducts.addAll(
            productsSnapshot.docs.map((doc) => Product.fromFirestore(doc)));
      }
      return recommendedProducts;
    } else {
      return [];
    }
  }

  Future<String?> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName;
      } else {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc['username'];
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 8), (Timer timer) {
      if (_pageController.hasClients) {
        int currentPage = _pageController.page?.toInt() ?? 0;
        int nextPage = (currentPage + 1) % _totalBanners;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.14,
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo,',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _username, // Tampilkan username yang sudah di-load
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(76, 175, 80, 1),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KeranjangPage()),
                );
              },
              icon: Icon(Icons.shopping_cart_outlined, size: 40.0),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                child: AbsorbPointer(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Mau cari apa?',
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[800],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color: Colors.grey[600]!,
                          width: 3.0,
                        ),
                      ),
                      contentPadding:
                          EdgeInsets.fromLTRB(25.0, 0.0, 0.0, 0.0),
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            FutureBuilder<List<BannerModel>>(
              future: _bannersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200.0,
                    margin: EdgeInsets.all(16.0),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No banners available'));
                } else {
                  List<BannerModel> banners = snapshot.data!;
                  return Container(
                    height: 200.0,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Stack(
                                  children: [
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        color: Colors.grey[300],
                                        height: 200.0,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Image.network(
                                      banners[index].imageUrl,
                                      fit: BoxFit.cover,
                                      height: 200.0,
                                      width: double.infinity,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        } else {
                                          return Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor:
                                                Colors.grey[100]!,
                                            child: Container(
                                              color: Colors.grey[300],
                                              height: 200.0,
                                              width: double.infinity,
                                            ),
                                          );
                                        }
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                            child: Text('Error loading banner'));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onPageChanged: (index) {
                            setState(() {});
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: banners.length,
                              effect: WormEffect(
                                activeDotColor: Colors.green,
                                dotColor: Colors.grey,
                                dotHeight: 8.0,
                                dotWidth: 8.0,
                                spacing: 16.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/makanan&minuman.svg',
                          title: 'Makanan \n& Minuman',
                          svgWidth: 35.0,
                          svgHeight: 35.0,
                          SvgmarginTop: 8.0,
                          isFirst: true,
                        ),
                        SizedBox(width: 18.0),
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/jasa.svg',
                          title: 'Jasa',
                          svgWidth: 40.0,
                          svgHeight: 40.0,
                          SvgmarginTop: 5.0,
                        ),
                        SizedBox(width: 18.0),
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/perlengkapan.svg',
                          title: 'Perlengkapan',
                          svgWidth: 30.0,
                          svgHeight: 30.0,
                          SvgmarginTop: 10.0,
                        ),
                        SizedBox(width: 18.0),
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/lainnya.svg',
                          title: 'Lainnya',
                          svgWidth: 40.0,
                          svgHeight: 40.0,
                          SvgmarginTop: 8.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Rekomendasi buat kamu',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  FutureBuilder<List<Product>>(
                    future: _recommendedProductsFuture, // Gunakan Future yang sudah disimpan
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No products available'));
                      } else {
                        List<Product> products = snapshot.data!;
                        List<Product> filteredProducts = products.where((product) {
                          return product.title.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(filteredProducts.length, (index) {
                              final product = filteredProducts[index];
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: ProductCard(product: product),
                              );
                            }),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String svgPath,
    required String title,
    bool isFirst = false,
    double svgWidth = 40.0,
    double svgHeight = 40.0,
    double SvgmarginTop = 10.0,
  }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Makanan \n& Minuman') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HalamanMakananMinuman()),
          );
        } else if (title == 'Perlengkapan') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HalamanPerlengkapan()),
          );
        } else if (title == 'Jasa') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HalamanJasa()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigation(selectedIndex: 1)),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: isFirst ? EdgeInsets.only(top: 16.0, left: 0.0) : EdgeInsets.only(left: 0.0),
              child: CategoryCard(
                svgPath: svgPath,
                title: '',
                svgWidth: svgWidth,
                svgHeight: svgHeight,
                SvgmarginTop: SvgmarginTop,
              ),
            ),
            SizedBox(height: 6.0),
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 100.0,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String svgPath;
  final String title;
  final double svgWidth;
  final double svgHeight;
  final double SvgmarginTop;

  CategoryCard({
    required this.svgPath,
    required this.title,
    this.svgWidth = 40.0,
    this.svgHeight = 40.0,
    this.SvgmarginTop = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70.0,
      height: 70.0,
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: SvgmarginTop),
          SvgPicture.asset(
            svgPath,
            width: svgWidth,
            height: svgHeight,
            color: Colors.green,
          ),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailPage extends StatelessWidget {
  final String title;

  CategoryDetailPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          'Detail Page: $title',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
