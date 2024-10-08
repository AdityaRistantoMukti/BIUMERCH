import 'dart:async';
import 'package:biumerch_mobile_app/modul4/page_payment/cart.dart';
import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/utils/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'banner_model.dart';
import 'banner_service.dart';
import 'product.dart';
import 'search_page.dart';
import 'package:biumerch_mobile_app/modul3/perlengkapan_page.dart';
import 'package:biumerch_mobile_app/modul3/makanan_minuman.dart';
import 'package:biumerch_mobile_app/modul3/jasa_page.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  late Timer _timer;
  late Future<List<BannerModel>> _bannersFuture;
  late Future<List<Product>> _productsFuture;
  late Future<List<Product>> _recommendedProductsFuture; // Tambahkan ini untuk rekomendasi
  late Future<List<Product>> _topProducts; // Tambahkan ini untuk rekomendasi
  final String _searchQuery = '';
  String _username = ''; // Variabel untuk menyimpan username
  bool _isLoggedIn = false; // Status login
  bool _isCaptchaVerified = false;  // Tambahkan status verifikasi captcha
  int _totalBanners = 0;
  User? currentUser;

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
    requestNotificationPermissions();
    _checkLoginStatus(); // Cek apakah user sudah login
    
    // Ambil produk tanpa perlu memeriksa login terlebih dahulu
    _productsFuture = fetchAllProducts();
    _topProducts = fetchTopProducts();

    if (_isLoggedIn) {
      _recommendedProductsFuture = _getRecommendedProducts(); // Inisialisasi Future rekomendasi
      _loadUsername(); // Panggil fungsi untuk load username
    }
    
    // 
    // Inisialisasi pengguna saat ini
    currentUser = FirebaseAuth.instance.currentUser;
    
     // Inisialisasi FCM dan dapatkan token
      FirebaseMessaging.instance.getToken().then((token) {
        print("FCM Token: $token");
        saveTokenToDatabase(token);
      });

     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text(notification.title ?? ''),
              content: Text(notification.body ?? ''),
            );
          },
        );
      }
    });
  }

   void saveTokenToDatabase(String? token) {
    if (token != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  void requestNotificationPermissions() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }
  // End

  Future<void> _checkLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Ambil status login dan status verifikasi CAPTCHA dari SharedPreferences
  bool isCaptchaVerified = prefs.getBool('isCaptchaVerified') ?? false;
  User? user = FirebaseAuth.instance.currentUser;

  if (mounted) {
    setState(() {
      // User dianggap login hanya jika sudah login ke Firebase dan verifikasi CAPTCHA berhasil
      _isLoggedIn = user != null && isCaptchaVerified; 
    });

    if (_isLoggedIn) {
      // Jika pengguna sudah login dan CAPTCHA diverifikasi, load username dan rekomendasi produk
      _loadUsername(); // Mengambil username
      _recommendedProductsFuture = _getRecommendedProducts(); // Ambil produk rekomendasi
    } else {
      // Jika pengguna tidak login atau CAPTCHA belum diverifikasi, ambil semua produk
      _productsFuture = fetchAllProducts();
    }
  }
}



 Future<void> _loadUsername() async {
    final userProfile = await fetchUserProfile();

    setState(() {
      _username = userProfile?['username'] ?? '';
    });
  }

  Future<List<Product>> fetchAllProducts() async {
  try {
    final List<Product> products = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('name', descending: false) // Mengurutkan berdasarkan title dari A-Z
        .get()
        .then((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
    return products;
  } catch (e) {
    print('Error fetching all products: $e');
    return [];
  }
}


  Future<List<Product>> fetchTopProducts() async {
    try {
      final List<Product> products = await FirebaseFirestore.instance
          .collection('products')
          .where('rating', isGreaterThanOrEqualTo: '4.5')
          .where('rating', isLessThanOrEqualTo: '5')
          .orderBy('rating', descending: true)
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
    // Ambil kategori dengan visitCount terbesar
    QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categoryVisits')
        .orderBy('visitCount', descending: true)
        .limit(1) // Hanya ambil 1 kategori dengan visitCount terbanyak
        .get();

    if (categorySnapshot.docs.isNotEmpty) {
      // Ambil kategori dengan visitCount terbesar
      String topCategory = categorySnapshot.docs.first.id;
      
      // Cek jika visitCount adalah 0
      int visitCount = categorySnapshot.docs.first['visitCount'] ?? 0;
      if (visitCount > 0) {
        // Ambil produk dari kategori dengan visitCount terbanyak
        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: topCategory)
            .orderBy('rating', descending: true)
            .limit(5) // Batasi jumlah produk yang diambil
            .get();

        return productsSnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();
      }
    }    
    // Jika tidak ada kategori dengan visitCount > 0 atau tidak ada kategori ditemukan
    return fetchTopProducts();
  } else {
    // Jika user tidak login, ambil semua produk
    return fetchAllProducts();
  }
}


//   Future<String?> _fetchUsername() async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user != null) {
//     String email = user.email ?? '';

//     try {
//       // Mencari dokumen user berdasarkan email
//       QuerySnapshot userQuery = await FirebaseFirestore.instance
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();

//       if (userQuery.docs.isNotEmpty) {
//         // Mengambil username dari dokumen user yang ditemukan
//         DocumentSnapshot userDoc = userQuery.docs.first;
//         return userDoc['username']; // Pastikan field ini ada di Firestore
//       } else {
//         // Jika user tidak ditemukan, log atau return null
//         print('User dengan email $email tidak ditemukan di Firestore');
//         return null;
//       }
//     } catch (e) {
//       print('Error saat mengambil username: $e');
//       return null;
//     }
//   }
//   return null;
// }



  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
      if (_pageController.hasClients) {
        int currentPage = _pageController.page?.toInt() ?? 0;
        int nextPage = (currentPage + 1) % _totalBanners;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isLoggedIn
    ? AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.13,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Halo,',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _username,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(76, 175, 80, 1),
                ),
              ),
            ],
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .where('buyerUID', isEqualTo: currentUser?.uid) // Menggunakan currentUser
                .snapshots(),
            builder: (context, roomSnapshot) {
              if (!roomSnapshot.hasData || roomSnapshot.data!.docs.isEmpty) {
                return _buildChatIcon(false);
              }

              List<Future<bool>> unreadMessagesFutures = roomSnapshot.data!.docs.map((roomDoc) async {
                QuerySnapshot unreadMessages = await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomDoc.id)
                    .collection('messages')
                    .where('isRead', isEqualTo: false)
                    .where('senderUID', isNotEqualTo: currentUser?.uid) // Menggunakan currentUser
                    .get();

                return unreadMessages.docs.isNotEmpty;
              }).toList();

              return FutureBuilder<List<bool>>(
                future: Future.wait(unreadMessagesFutures),
                builder: (context, unreadResults) {
                  if (!unreadResults.hasData) {
                    return _buildChatIcon(false); 
                  }

                  bool hasUnreadMessages = unreadResults.data!.contains(true);

                  return _buildChatIcon(hasUnreadMessages);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KeranjangPage()),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, size: 40.0),
            ),
          ),
        ],
      )
    : null ,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: _isLoggedIn ? 8.0 : 50.0, // Jarak dari atas layar
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchPage()),
                  );
                },
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
                          const EdgeInsets.fromLTRB(25.0, 0.0, 0.0, 0.0),
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<BannerModel>>(
              future: _bannersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200.0,
                    margin: const EdgeInsets.all(16.0),
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
                  return const Center(child: Text('No banners available'));
                } else {
                  List<BannerModel> banners = snapshot.data!;
                  return SizedBox(
                    height: 200.0,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.all(16.0),
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
                                            highlightColor: Colors.grey[100]!,
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
                                        return const Center(
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
                              effect: const WormEffect(
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
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
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
                        const SizedBox(width: 18.0),
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/jasa.svg',
                          title: 'Jasa',
                          svgWidth: 40.0,
                          svgHeight: 40.0,
                          SvgmarginTop: 5.0,
                        ),
                        const SizedBox(width: 18.0),
                        _buildCategoryCard(
                          context: context,
                          svgPath: 'assets/icons/Kategori/perlengkapan.svg',
                          title: 'Perlengkapan',
                          svgWidth: 30.0,
                          svgHeight: 30.0,
                          SvgmarginTop: 10.0,
                        ),
                        const SizedBox(width: 18.0),
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
                  const Text(
                    'Rekomendasi buat kamu',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  FutureBuilder<List<Product>>(
                    future: _isLoggedIn ? _recommendedProductsFuture : _topProducts, // Pilih Future berdasarkan status login
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Warna loader hijau
                        ));
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No products available'));
                      } else {
                        List<Product> products = snapshot.data!;
                        
                        List<Product> filteredProducts = products.take(5).toList();
                        // List<Product> filteredProducts = products.where((product) {
                        //   return product.title.toLowerCase().contains(_searchQuery.toLowerCase());
                        // }).take(5).toList();  

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(filteredProducts.length, (index) {
                              final product = filteredProducts[index];
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Produk Lainnya',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  FutureBuilder<List<Product>>(
                    future: _productsFuture, // Ambil semua produk
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Warna loader hijau
                        ));
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No products available'));
                      } else {
                        List<Product> products = snapshot.data!;

                        final double screenWidth = MediaQuery.of(context).size.width;
                        final double screenHeight = MediaQuery.of(context).size.height;

                        // Hitung childAspectRatio berdasarkan lebar layar dan tinggi yang diinginkan
                        final double childAspectRatio = (screenWidth / 1) / (screenHeight / 3.1); // Adjust this formula

                        return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Menambahkan padding
                            shrinkWrap: true, // Agar GridView tidak mengambil seluruh tinggi layar
                            physics: const NeverScrollableScrollPhysics(), // Menghindari konflik scroll dengan SingleChildScrollView
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height * 0.87),
                            ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(product: product); // Gunakan widget ProductCard yang sama
                          },
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

  Widget _buildChatIcon(bool hasUnreadMessages) {
  return Padding(
    padding: const EdgeInsets.only(right: 16.0),
    child: Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/listChatPembeli');
          },
          icon: const Icon(
            Icons.chat_bubble_outline,
            size: 30.0,
            color: Color(0xFF194D42),
          ),
        ),
        if (hasUnreadMessages)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '!', // Bisa juga menampilkan jumlah pesan yang belum terbaca
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
              margin: isFirst ? const EdgeInsets.only(top: 16.0, left: 0.0) : const EdgeInsets.only(left: 0.0),
              child: CategoryCard(
                svgPath: svgPath,
                title: '',
                svgWidth: svgWidth,
                svgHeight: svgHeight,
                SvgmarginTop: SvgmarginTop,
              ),
            ),
            const SizedBox(height: 6.0),
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
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

  const CategoryCard({super.key, 
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
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
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
              style: const TextStyle(
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

  const CategoryDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          'Detail Page: $title',
          style: const TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}

