import 'package:biumerch_mobile_app/modul2/Detail_produk.dart';
import 'package:biumerch_mobile_app/modul2/edit_product_screen.dart';
import 'package:biumerch_mobile_app/modul2/saldo_pengguna.dart';
import 'package:biumerch_mobile_app/modul3/listChat.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'editprofile_toko.dart';
import 'tambah_produk.dart';
import 'kelolapesanan.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart'; // Import for BottomNavigation icons

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
  List<Map<String, dynamic>> filteredProducts = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String searchQuery = '';
  int _selectedIndex = 0; // Add this for BottomNavigationBar state

  final _numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProducts();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).update({
        'storeName': storeName,
        'email': email,
        'phoneNumber': phoneNumber,
        'storeLogo': imagePath,
      });
    } catch (e) {
      print('Gagal menyimpan profil toko: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('storeId', isEqualTo: widget.storeId)
          .get();
          
      final loadedProducts = querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      loadedProducts.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        products = List<Map<String, dynamic>>.from(loadedProducts);
        filteredProducts = List<Map<String, dynamic>>.from(products);
      });
    } catch (e) {
      print('Gagal memuat produk: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _navigateToAddProduct() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductFormScreen(storeId: widget.storeId, productId: null),
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

  Future<void> _navigateToDetailProductPage(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailProductPage(
          productId: product['id'],
          title: product['name'],
          price: int.parse(product['price'].replaceAll('.', '')),
          rating: product['rating'] != null
              ? double.tryParse(product['rating'].toString()) ?? 4.2
              : 4.2,
          description: product['description'] ?? 'Tidak ada deskripsi',
          imageUrls: List<String>.from(product['imageUrls']),
        ),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  void _filterProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredProducts = products.where((product) {
        return product['name'].toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    // Add page navigation logic here if needed
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40, // Kecilkan ukuran height TextField
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: Icon(Icons.search, color: Colors.black), // Warna ikon pencarian menjadi hitam
                    contentPadding: EdgeInsets.symmetric(vertical: 10), // Kecilkan padding konten
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0), // Rounded edge
                      borderSide: const BorderSide(color: Colors.black, width: 2.0), // Warna border hitam
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: const BorderSide(color: Colors.black, width: 2.0), // Border hitam saat fokus
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: const BorderSide(color: Colors.black, width: 2.0), // Border hitam saat tidak fokus
                    ),
                  ),
                  onChanged: (query) => _filterProducts(query),
                ),
              )
            : const Text(
                'Toko Saya',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 252, 253, 252),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  searchQuery = '';
                  filteredProducts = List<Map<String, dynamic>>.from(products);
                }
              });
            },
          ),
        ],
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
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF62E703)),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double boxWidth = constraints.maxWidth * 0.3;

                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          // Bagian yang mengubah klik pada "Saldo"
                          InkWell(
                            onTap: () {
                              // Navigasi ke halaman saldo
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TarikSaldoScreen()), // Navigasi ke halaman Tarik Saldo
                              );
                            },
                            child: Container(
                              width: boxWidth,
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
                                    '0',
                                    style: TextStyle(
                                      color: Color(0xFF0B4D3B),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bagian ini untuk Pesanan
                          Container(
                            width: boxWidth,
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

                          // Bagian untuk Chat
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
                                    width: boxWidth,
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
                                        CircularProgressIndicator(),
                                      ],
                                    ),
                                  );
                                }

                                Set<String> uniqueBuyers = {};

                                for (var doc in snapshot.data!.docs) {
                                  uniqueBuyers.add(doc['buyerUID']);
                                }

                                return Container(
                                  width: boxWidth,
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
                                        uniqueBuyers.length.toString(),
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
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToAddProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF62E703),
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
                    crossAxisCount: MediaQuery.of(context).size.width > 1200
                        ? 6 // Jika layar lebar, tampilkan 6 produk per baris
                        : MediaQuery.of(context).size.width > 900
                            ? 4 // Jika layar sedang, tampilkan 4 produk per baris
                            : MediaQuery.of(context).size.width > 600
                                ? 3 // Jika layar kecil, tampilkan 3 produk per baris
                                : 2, // Untuk layar lebih kecil, tampilkan 2 produk per baris
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var product = filteredProducts[index];
                    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                    return GestureDetector(
                      onTap: () {
                        _navigateToDetailProductPage(product);
                      },
                      child: Container(
                        width: 250,
                        margin: const EdgeInsets.all(7.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 3,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              margin: const EdgeInsets.all(8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.network(
                                  product['imageUrls'] != null && product['imageUrls'].isNotEmpty
                                      ? product['imageUrls'][0]
                                      : 'https://via.placeholder.com/150',
                                  height: MediaQuery.of(context).size.height * 0.15,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    formatter.format(int.parse(product['price'].replaceAll('.', ''))),
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF319F43),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.yellow[700],
                                          size: 16.0,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          product['rating'] != null
                                              ? product['rating'].toString()
                                              : '4.2',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
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
      
      // Add BottomNavigationBar
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
        onTap: _onItemTapped, // Logic to handle tap
      ),
    );
  }
}
