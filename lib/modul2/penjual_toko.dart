import 'package:biumerch_mobile_app/modul2/chat_page.dart';
import 'package:biumerch_mobile_app/modul3/chat_penjual_page.dart';
import 'package:biumerch_mobile_app/modul3/listChat.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'editprofile_toko.dart';
import 'tambah_produk.dart';
import 'kelolapesanan.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SellerProfileScreen extends StatefulWidget {
  final String storeId;

  const SellerProfileScreen({super.key, required this.storeId});

  @override
  _SellerProfileScreenState createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  String storeName = '';
  String email = '';
  String phoneNumber = '';
  String imagePath = '';
  List<Map<String, dynamic>> products = [];
  bool _isLoading = false;
  final _numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProducts();
  }

  Future<void> _loadProfile() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
      if (doc.exists) {
        setState(() {
          storeName = doc['storeName'] ?? 'Nama Toko';
          email = doc['email'] ?? 'email@contoh.com';
          phoneNumber = doc['phoneNumber'] ?? '+62 812-3456-7890';
          imagePath = doc['storeLogo'] ?? 'assets/images/user.jpg';
        });
      } else {
        setState(() {
          storeName = 'Nama Toko';
          email = 'email@contoh.com';
          phoneNumber = '+62 812-3456-7890';
          imagePath = 'assets/images/user.jpg';
        });
      }
    } catch (e) {
      print('Gagal memuat profil toko: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).update({
        'storeName': storeName,
        'email': email,
        'phoneNumber': phoneNumber,
        'storeLogo': imagePath,
      });
    } catch (e) {
      print('Gagal menyimpan profil toko: $e');
    }
  }

  void updateProfile(String newName, String newEmail, String newPhone, String newImagePath) {
    setState(() {
      storeName = newName;
      email = newEmail;
      phoneNumber = newPhone;
      imagePath = newImagePath;
    });
    _saveProfile();
  }

  Future<void> _loadProducts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
      final loadedProducts = querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        products = List<Map<String, dynamic>>.from(loadedProducts);
      });
    } catch (e) {
      print('Gagal memuat produk: $e');
    }
  }

  Future<void> _deleteProduct(String productId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      setState(() {
        products.removeWhere((product) => product['id'] == productId);
      });

      // Menampilkan pop-up konfirmasi berhasil dihapus
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Produk berhasil dihapus',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Gagal menghapus produk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus produk')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
      for (var doc in productsSnapshot.docs) {
        await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
      }

      await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko berhasil dihapus')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    } catch (e) {
      print('Gagal menghapus toko: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus toko')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddProduct() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductFormScreen(storeId: widget.storeId),
        ),
      );

      if (result != null) {
        _loadProducts();
      }
    } catch (e) {
      print('Gagal menuju halaman tambah produk: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<ImageInfo> _getImageInfo(String imageUrl) async {
    final Completer<ImageInfo> completer = Completer();
    final image = NetworkImage(imageUrl);
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    });

    image.resolve(const ImageConfiguration()).addListener(listener);
    return completer.future;
  }

  void _showProductImages(BuildContext context, List<String> imageUrls) {
    PageController pageController = PageController();
    Timer? timer;

    void autoSlide() {
      timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        if (pageController.page == imageUrls.length - 1) {
          pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        } else {
          pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }

    autoSlide();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: AspectRatio(
            aspectRatio: 1,
            child: FutureBuilder<ImageInfo>(
              future: _getImageInfo(imageUrls[0]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  final imageInfo = snapshot.data!;
                  final aspectRatio = imageInfo.image.width / imageInfo.image.height;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: PageView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: pageController,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return AspectRatio(
                              aspectRatio: aspectRatio,
                              child: Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SmoothPageIndicator(
                        controller: pageController,
                        count: imageUrls.length,
                        effect: const WormEffect(
                          dotHeight: 8.0,
                          dotWidth: 8.0,
                          spacing: 8.0,
                          dotColor: Colors.grey,
                          activeDotColor: Color(0xFF319F43),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        );
      },
    ).then((_) {
      if (timer != null) {
        timer!.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height / 1.6); // Misalnya
  
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Toko Saya',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: imagePath.startsWith('assets')
                            ? AssetImage(imagePath)
                            : NetworkImage(imagePath) as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF319F43),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF319F43),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                storeName: storeName,
                                email: email,
                                phoneNumber: phoneNumber,
                                imagePath: imagePath,
                              ),
                            ),
                          );

                          if (result != null) {
                            updateProfile(
                              result['name'],
                              result['email'],
                              result['phone'],
                              result['imagePath'],
                            );
                            _loadProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(86, 202, 3, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                 const SizedBox(height: 20),
                  Wrap(
                    spacing: 10, // Horizontal space between boxes
                    runSpacing: 10, // Vertical space between boxes
                    children: <Widget>[
                      // Box for Saldo
                      Container(
                        width: 110, // Consistent width for each box
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              'assets/images/saldo.jpg',
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Saldo',
                              style: TextStyle(
                                color: Color(0xFF0B4D3B),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '1.000.000',
                              style: TextStyle(
                                color: Color(0xFF0B4D3B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Box for Pesanan with Navigation
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const KelolaPesananScreen()),
                          );
                        },
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: <Widget>[
                              Image.asset(
                                'assets/images/pesanan.jpg',
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pesanan',
                                style: TextStyle(
                                  color: Color(0xFF0B4D3B),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                '12',
                                style: TextStyle(
                                  color: Color(0xFF0B4D3B),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // The Chat Box with dynamic total of unique buyers
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ListChat(storeId: widget.storeId)),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('rooms')
                              .where('sellerUID', isEqualTo: widget.storeId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                width: 110,
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F3F3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: const <Widget>[
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 30,
                                      color: Color(0xFF0B4D3B),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Chat',
                                      style: TextStyle(
                                        color: Color(0xFF0B4D3B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    CircularProgressIndicator(), // Loading spinner while data is being fetched
                                  ],
                                ),
                              );
                            }

                            // Use a Set to keep track of unique buyerUIDs
                            Set<String> uniqueBuyers = {};

                            for (var doc in snapshot.data!.docs) {
                              uniqueBuyers.add(doc['buyerUID']);
                            }

                            return Container(
                              width: 110,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: <Widget>[
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 30,
                                    color: Color(0xFF0B4D3B),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Chat',
                                    style: TextStyle(
                                      color: Color(0xFF0B4D3B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    uniqueBuyers.length.toString(), // Display total unique buyers
                                    style: const TextStyle(
                                      color: Color(0xFF0B4D3B),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToAddProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(86, 202, 3, 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'Tambah Produk',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),                
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7, // Menyesuaikan rasio aspek dengan konten
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      return GestureDetector(
                        onLongPress: () async {
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Penghapusan'),
                                content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            _deleteProduct(product['id']);
                          }
                        },
                        onTap: () {
                          _showProductImages(context, List<String>.from(product['imageUrls']));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 252, 250, 250).withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Padding untuk memberikan jarak antara gambar dan container utama
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0), // Atur padding sesuai kebutuhan
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8), // Radius pada container penampung gambar
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: product['imageUrls'] != null && product['imageUrls'].isNotEmpty
                                              ? NetworkImage(product['imageUrls'][0])
                                              : const AssetImage('assets/images/default.jpg') as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      product['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),              
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _numberFormat.format(int.parse(product['price'].replaceAll('.', ''))),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF319F43),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF319F43),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${product['rating'] ?? '4.2'}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),      
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF319F43)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
