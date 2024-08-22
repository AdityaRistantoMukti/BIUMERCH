  import 'package:biumerch_mobile_app/food_detail_page.dart';
  import 'package:biumerch_mobile_app/halaman_keranjang.dart';
  import 'package:biumerch_mobile_app/history_page.dart';
  import 'package:biumerch_mobile_app/jasa_page.dart';  
  import 'package:biumerch_mobile_app/makanan_minuman.dart';
  import 'package:biumerch_mobile_app/category_page.dart';
  import 'package:biumerch_mobile_app/perlengkapan_page.dart';
  import 'package:biumerch_mobile_app/profile_page.dart';
  import 'package:biumerch_mobile_app/search_page.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:biumerch_mobile_app/product.dart'; // Pastikan untuk mengimpor file ini
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_svg/flutter_svg.dart';
  import 'dart:async';
  import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import paket
  import 'banner_model.dart';
  import 'banner_service.dart';
  import 'package:intl/intl.dart';

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
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    CategoryPage(),
    HistoryPage(),
    ProfilePage(),
    HalamanMakananMinuman(), // Halaman Makanan & Minuman
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.14), // 15% dari tinggi layar
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.00, // Padding atas yang dapat disesuaikan
            // bottom: MediaQuery.of(context).size.height * 0., // Tambahkan sedikit padding bawah untuk menghindari pemotongan teks
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0), // Padding kiri untuk judul
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
                  FutureBuilder<String?>(
                    future: _fetchUsername(), // Fungsi untuk mengambil username dari Firestore
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(); // Tidak menampilkan apapun saat loading
                      } else if (snapshot.hasError) {
                        return Text("Error"); // Menangani error jika ada
                      } else {
                        return Text(
                          snapshot.data ?? "", // Tampilkan username jika sudah siap
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromRGBO(76, 175, 80, 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0), // Padding kanan untuk ikon keranjang
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HalamanKeranjang()),
                    );
                  },
                  icon: Icon(Icons.shopping_cart_outlined, size: 40.0), // Perbesar ikon keranjang menjadi 40.0
                ),
              ),
            ],
            // backgroundColor: Colors.white,
            elevation: 0, // Remove shadow
          ),
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _onItemTapped(index);
          });
        },
      ),
    );
  }

  Future<String?> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return userDoc['username'];
    }
    return null;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CategoryPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HistoryPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        break;
    }
  }
}


  class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  late Timer _timer;
  late Future<List<BannerModel>> _bannersFuture; 
  late Future<List<Product>> _productsFuture;    
  String _searchQuery = '';
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
    _productsFuture = fetchProducts(); // Mengambil produk dari backend
    // _productsFuture = fetchTrendingProducts();
  }
  // Mendapatkan produk dari firebase
  Future<List<Product>> fetchProducts() async {
    // Implementasikan pengambilan produk dari backend atau Firestore
    // Misalnya:
    final List<Product> products = await FirebaseFirestore.instance.collection('products')
      .where('rating', isEqualTo: '4.5').get().then((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
    return products; // Sementara, kembalikan list kosong
  }

  // SEO
  Future<List<Product>> fetchTrendingProducts() async {
  final trendingQueries = await FirebaseFirestore.instance
      .collection('searchQueries')
      .orderBy('count', descending: true)
      .limit(5)  // Misalnya, ambil 5 kata kunci paling populer
      .get();

    List<Product> trendingProducts = [];
    for (var query in trendingQueries.docs) {
      final products = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query['keyword'])
          .where('name', isLessThanOrEqualTo: query['keyword'] + '\uf8ff')
          .get();
      trendingProducts.addAll(products.docs.map((doc) => Product.fromFirestore(doc)).toList());
    }
    return trendingProducts;
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Search bar
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
              },
             child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                child: AbsorbPointer(  // AbsorbPointer untuk mencegah interaksi
                  child: TextField(
                    enabled: false,  // Disable editing in the current page
                    // controller: TextEditingController(text: query),
                    decoration: InputDecoration(
                      hintText: 'Mau cari apa?',
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[800],  // Mengatur warna ikon agar lebih jelas
                      ),  // Menempatkan ikon di pojok kanan
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),  // Mengubah radius sesuai UI yang diinginkan
                        borderSide: BorderSide(
                          color: Colors.grey[600]!,  // Mengatur warna border agar lebih jelas
                          width: 3.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.fromLTRB(25.0, 0.0, 0.0, 0.0),  // Padding: Left, Top, Right, Bottom
                      hintStyle: TextStyle(
                        color: Colors.grey[600],  // Set hint text color
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Banner
            SizedBox(height: 16),
            FutureBuilder<List<BannerModel>>(
              future: _bannersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                image: DecorationImage(
                                  image: NetworkImage(banners[index].imageUrl),
                                  fit: BoxFit.cover,
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
            // End Banner
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
                    future: _productsFuture,
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
                                  maxWidth: 200, // Ensure each card has a valid width
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
          // Cek jika kategori adalah "Makanan & Minuman"
          if (title == 'Makanan \n& Minuman') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HalamanMakananMinuman()), // Ganti dengan halaman yang sesuai
            );
          } else if(title == 'Perlengkapan'){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HalamanPerlengkapan()), // Ganti dengan halaman yang sesuai
            );
          }else if(title == 'Jasa'){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HalamanJasa()), // Ganti dengan halaman yang sesuai
            );
          } else {
            // Logika navigasi lainnya untuk kategori yang berbeda
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CategoryPage()),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0), // No horizontal padding for the first card
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure Column fits content
            children: [
              Container(
                margin: isFirst ? EdgeInsets.only(top: 16.0, left: 0.0) : EdgeInsets.only(left: 0.0), // Align card first to left, others to right
                child: CategoryCard(
                  svgPath: svgPath,
                  title: '',    
                  svgWidth: svgWidth, // Pass the width parameter
                  svgHeight: svgHeight, // Pass the height parameter     
                  SvgmarginTop: SvgmarginTop,
                    
                ),
              ),
              SizedBox(height: 6.0),
              Align(
                alignment: Alignment.center, // Center text below card
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 100.0, // Set maximum width to match the card width
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center, // Center text
                    style: TextStyle(
                      color: Colors.green[800], // Dark green color
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    maxLines: 2, // Limit to 2 lines
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
      this.svgWidth = 40.0, // Default width
      this.svgHeight = 40.0, // Default height
      this.SvgmarginTop = 10.0, // Default top margin
      
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

