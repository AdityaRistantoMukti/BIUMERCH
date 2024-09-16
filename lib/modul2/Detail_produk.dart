import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_product_screen.dart';

class DetailProductPage extends StatefulWidget {
  final String productId;
  final String title;
  final int price;
  final double rating;
  final String description;
  final List<String> imageUrls;

  const DetailProductPage({
    Key? key,
    required this.productId,
    required this.title,
    required this.price,
    required this.rating,
    required this.description,
    required this.imageUrls,
  }) : super(key: key);

  @override
  _DetailProductPageState createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  late PageController _pageController;
  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isLoading = false;
  Map<String, dynamic>? _productData;
  String _productName = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productName = widget.title;
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        setState(() {
          _productData = doc.data() as Map<String, dynamic>?;
          if (_productData != null && _productData!['price'] is String) {
            _productData!['price'] = int.parse(_productData!['price']);
          }
          _productName = _productData?['name'] ?? widget.title;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Gagal memuat data produk: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).delete();
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Produk dihapus"),
            content: const Text("Produk telah berhasil dihapus."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true); // Mengembalikan true ke halaman sebelumnya
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Gagal menghapus produk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus produk')),
      );
    }
  }

  void _confirmDeleteProduct() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmEditProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          productId: widget.productId,
          storeId: 'your_store_id',
          productDescription: '',
        ),
      ),
    );

    if (result == true) {
      _loadProductData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope( // Menggunakan WillPopScope di luar Scaffold
      onWillPop: () async {
        Navigator.pop(context, true); // Mengirim true saat kembali
        return false; // Mencegah navigasi default agar kita bisa kontrol manual
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _productName,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Mengirim true saat pengguna menekan tombol back
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _confirmEditProduct();
                } else if (value == 'delete') {
                  _confirmDeleteProduct();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'edit',
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Edit Produk'),
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Hapus Produk'),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_productData != null) ...[
              Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 4.0),
                          SizedBox(
                            width: double.infinity,
                            height: screenWidth * 0.6,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: widget.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      image: DecorationImage(
                                        image: NetworkImage(widget.imageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (widget.imageUrls.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: widget.imageUrls.length,
                                  effect: const WormEffect(
                                    dotHeight: 8.0,
                                    dotWidth: 8.0,
                                    activeDotColor: Colors.green,
                                    dotColor: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      _currencyFormatter.format(_productData?['price'] ?? widget.price),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenWidth * 0.01),
                                      decoration: BoxDecoration(
                                        color: Colors.green[700],
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.star,
                                              color: Colors.yellow[700],
                                              size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.01),
                                          Text(
                                            "${widget.rating}",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenWidth * 0.04),
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 255, 249, 249),
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 2,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Deskripsi:',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: screenWidth * 0.02),
                                      Text(
                                        _productData?['description'] ?? widget.description,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
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
                  ),
                ],
              ),
            ],
            if (_isLoading)
              Container(
                color: const Color.fromARGB(137, 255, 254, 254),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
