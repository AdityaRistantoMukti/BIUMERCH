import 'package:biumerch_mobile_app/modul3/chat_penjual_page.dart';
import 'package:biumerch_mobile_app/modul4/page_payment/cart.dart';
import 'package:biumerch_mobile_app/modul4/page_payment/checkout_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodDetailPage extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final String productId;  // Add this line
  final double price;
  final double rating;
  final String description;
  final String category;
  final String storeId;

  FoodDetailPage({
    required this.image,
    required this.title,
    required this.price,
    required this.rating,
    required this.description,
    required this.category,
    required this.storeId,
    required this.productId,
  });

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  String? _selectedOption;
  String _additionalNotes = ''; 

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    name: 'IDR',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

// Fungsi - Fungsi
  // Tambahkan method untuk menyimpan catatan tambahan dari modal
  void _setAdditionalNotes(String notes) {
    setState(() {
      _additionalNotes = notes;
    });
  }
  // End  
  // Fungsi validasi user ingin chat dengan penjual
  void _showChatConfirmationDialog(BuildContext context, DocumentReference roomRef, String roomId, String buyerUID, String sellerUID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Hubungi Penjual"),
          content: Text("Apakah Anda ingin menghubungi penjual terkait produk ini?"),
          actions: <Widget>[
            TextButton(
              child: Text("Tidak"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: Text("Ya"),
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog

                // Buat room baru di Firestore
                await roomRef.set({
                  'buyerUID': buyerUID,
                  'sellerUID': sellerUID,
                  'lastMessage': '',
                  'lastMessageTimestamp': Timestamp.now(),
                });

                // Arahkan ke halaman chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HalamanChatPenjual(
                      roomId: roomId, 
                      buyerUID: buyerUID, 
                      sellerUID: sellerUID,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // 
   void _startChatWithSeller() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String buyerUID = user.uid;
      String sellerUID = widget.storeId; // Menggunakan storeId sebagai UID penjual
      String roomId = 'room_${buyerUID}_$sellerUID';
      DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

      // Cek apakah room sudah ada
      DocumentSnapshot roomSnapshot = await roomRef.get();
      if (!roomSnapshot.exists) {
        // Jika room belum ada, tampilkan dialog konfirmasi
        _showChatConfirmationDialog(context, roomRef, roomId, buyerUID, sellerUID);
      } else {
        // Jika room sudah ada, langsung buka halaman chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HalamanChatPenjual(
              roomId: roomId, 
              buyerUID: buyerUID, 
              sellerUID: sellerUID,
            ),
          ),
        );
      }
    } else {
      // Jika user belum login, arahkan ke halaman login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
// End
// Validasi user memilih Opsi Menu
  void _showValidationMessage() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'Peringatan',
              style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Anda harus memilih salah satu opsi sebelum melanjutkan.',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF707070),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
// 

  bool _validateSelection() {
  if (_selectedOption == null) {
    _showValidationMessage();
    return false;
  }
  return true;
}
// End
// Fungsi Memasukkan produk ke keranjang
  Future<void> _addToCart() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      CollectionReference cart = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Cart');

      final String? imageUrl;
      if (widget.image is NetworkImage) {
        imageUrl = (widget.image as NetworkImage).url;
      } else {
        imageUrl = null;
      }

      if (imageUrl != null) {
        QuerySnapshot existingItem = await cart
            .where('productName', isEqualTo: widget.title)
            .where('storeId', isEqualTo: widget.storeId)
            .where('selectedOption', isEqualTo: _selectedOption ?? '')
            .get();

        if (existingItem.docs.isNotEmpty) {
          var existingDoc = existingItem.docs.first;
          int existingQuantity = (existingDoc['quantity'] as num).toInt();
          await cart.doc(existingDoc.id).update({
            'quantity': existingQuantity + _quantity,
          });
        } else {
          await cart.add({
            'productId': widget.productId,  // Now productId is defined
            'productName': widget.title,
            'productPrice': widget.price,
            'productImage': imageUrl,
            'quantity': _quantity,
            'selectedOption': _selectedOption ?? '',
            'category': widget.category,
            'storeId': widget.storeId,
          });
        }

        // Memulai animasi setelah berhasil menambahkan ke keranjang
        _animationController.forward(from: 0.0);
      } else {
        print('Error: Image URL is null');
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min, // Menyesuaikan ukuran kolom agar tidak terlalu tinggi
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 40.0, // Mengatur ukuran ikon
                ),
                SizedBox(height: 8.0), // Jarak antara ikon dan teks
                Text(
                  "Silahkan Login Terlebih Dahulu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0, // Mengatur ukuran font
                  ),
                  textAlign: TextAlign.center, // Menyelaraskan teks ke tengah
                ),
              ],
            ),
           
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                child: Text("Batal"),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: Text("Login"),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.pushReplacementNamed(context, '/login'); // Arahkan ke halaman login
                },
              ),
            ],
          );
        },
      );
    }
  }
// Tutuo
// Fungsi Mengirim data produk ke halaman checkout
Future<void> _proceedToCheckout(BuildContext context) async {

  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final String? imageUrl;
    if (widget.image is NetworkImage) {
      imageUrl = (widget.image as NetworkImage).url;
    } else {
      imageUrl = null;
    }

    if (imageUrl != null) {
      var selectedItems = [
        {
          'productId': widget.productId,  // Now productId is defined
          'productName': widget.title,
          'productPrice': widget.price,
          'productImage': imageUrl,
          'quantity': _quantity,
          'selectedOption': _selectedOption ?? '',
          'category': widget.category,
          'storeId': widget.storeId,
          'additionalNotes': _additionalNotes,
        }
      ];

      // Navigate to CheckoutWidget
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutWidget(
            checkedItems: selectedItems,
            totalPrice: (widget.price * _quantity).toInt(),
             additionalNotes: _additionalNotes, 
          ),
        ),
      );
    } else {
      print('Error: Image URL is null');
    }
  } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min, // Menyesuaikan ukuran kolom agar tidak terlalu tinggi
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 40.0, // Mengatur ukuran ikon
                ),
                SizedBox(height: 8.0), // Jarak antara ikon dan teks
                Text(
                  "Silahkan Login Terlebih Dahulu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0, // Mengatur ukuran font
                  ),
                  textAlign: TextAlign.center, // Menyelaraskan teks ke tengah
                ),
              ],
            ),
           
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                child: Text("Batal"),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: Text("Login"),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.pushReplacementNamed(context, '/login'); // Arahkan ke halaman login
                },
              ),
            ],
          );
        },
      );
  }
}
// Tutup


// Code inti
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.grey,
            height: 2.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 6.0),
                      Container(
                        width: double.infinity,
                        height: screenWidth * 0.6,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: widget.image,
                            fit: BoxFit.cover,
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
                                  _currencyFormatter.format(widget.price),
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
                                color: Color.fromARGB(255, 255, 249, 249),
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
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
                                    widget.description,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.04),
                            Text(
                              'Ulasan Pembeli:',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            ReviewCard(
                              username: 'Madeline',
                              timeAgo: '1 hari yang lalu',
                              rating: 4.0,
                              comment:
                                  'Geprek nya enak dan sambal nya juga sangat pedas',
                            ),
                            ReviewCard(
                              username: 'Irfan',
                              timeAgo: '2 jam yang lalu',
                              rating: 5.0,
                              comment: 'Mantap!',
                            ),
                            SizedBox(height: screenWidth * 0.06),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.chat,
                          color: Colors.grey[700], size: screenWidth * 0.07),
                      onPressed: () {
                        _startChatWithSeller();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.shopping_cart,
                          color: Colors.grey[700], size: screenWidth * 0.07),
                      onPressed: () {
                        _showOptionsModal(context); 
                      },
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (BuildContext context) {
                            return _buildBottomSheet(context);
                          },
                        );
                      },
                      child: Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 98, 231, 3),
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.12,
                            vertical: screenWidth * 0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Berhasil ditambahkan ke keranjang",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

void _showOptionsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _buildBottomSheet2(context);
    },
  );
}

  Widget _buildBottomSheet(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,  // Mengatur tinggi berdasarkan isi
            children: <Widget>[
              Container(
                width: screenWidth * 0.15,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(
                      image: widget.image,
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Total Harga: ${_currencyFormatter.format(widget.price * _quantity)}",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Divider(color: Colors.grey[300], thickness: 1),
              // SizedBox(height: screenWidth * 0.05),
              // Text(
              //     "Opsi :",
              //       style: TextStyle(
              //       fontSize: screenWidth * 0.04,
              //       fontWeight: FontWeight.bold,
              //     ),
              //  ),
              // SizedBox(height: screenWidth * 0.02),
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //     children: [
              //     _buildOptionButton(setState, "Paha Atas"),
              //     _buildOptionButton(setState, "Paha Bawah"),
              //     _buildOptionButton(setState, "Kulit Ayam"),
              //     ],
              // ),                                                      
              SizedBox(height: screenWidth * 0.05),
              Text(
                "Catatan Tambahan :",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              TextField(
                decoration: InputDecoration(
                  hintText: "Catatan : Bagian paha atas, sambal di pisah",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _additionalNotes = value; // Simpan catatan tambahan
                  });
                },
              ),
              SizedBox(height: screenWidth * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Jumlah",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_quantity > 1) {
                              _quantity--;
                            }
                          });
                        },
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "$_quantity",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.05),
              ElevatedButton(
                onPressed: () async {
                  // if (_validateSelection()) {
                  // }
                    Navigator.of(context).pop(); // Tutup bottom sheet
                    await _proceedToCheckout(context); // Lanjutkan ke checkout
                },
                child: Text(
                  "Pesan Sekarang",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 98, 231, 3),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.29,
                      vertical: screenWidth * 0.03),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget _buildBottomSheet2(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,  // Menyesuaikan tinggi dengan isi
            children: <Widget>[
              Container(
                width: screenWidth * 0.15,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(
                      image: widget.image,
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Total Harga: ${_currencyFormatter.format(widget.price * _quantity)}",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Divider(color: Colors.grey[300], thickness: 1),
              SizedBox(height: screenWidth * 0.05),
              Text(
                "Catatan Tambahan :",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              TextField(
                decoration: InputDecoration(
                  hintText: "Catatan : Bagian paha atas, sambal di pisah",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _additionalNotes = value; // Simpan catatan tambahan
                  });
                },
              ),
              SizedBox(height: screenWidth * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Jumlah",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_quantity > 1) {
                              _quantity--;
                            }
                          });
                        },
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "$_quantity",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.05),  
              Padding(
                padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                child: ElevatedButton(
                  onPressed: () async {
                    // if (_validateSelection()) {
                    // }
                      Navigator.of(context).pop(); // Tutup bottom sheet
                      await _addToCart(); // Tambahkan ke keranjang
                  },
                  child: Text(
                    "Tambahkan ke keranjang",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 98, 231, 3),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.2,
                        vertical: screenWidth * 0.03),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



 Widget _buildOptionButton(StateSetter setState, String label) {
  final screenWidth = MediaQuery.of(context).size.width;

  return ElevatedButton(
    onPressed: () {
      setState(() {
        if (_selectedOption == label) {
          _selectedOption = null; // Batalkan pilihan jika opsi yang sama diklik lagi
        } else {
          _selectedOption = label; // Pilih opsi jika berbeda
        }
      });
    },
    child: Text(
      label,
      style: TextStyle(
        color: _selectedOption == label ? Colors.white : Colors.black,
        fontSize: screenWidth * 0.04,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: _selectedOption == label
          ? Colors.green
          : Colors.grey[300],
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, vertical: screenWidth * 0.025),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  );
}

}

class ReviewCard extends StatelessWidget {
  final String username;
  final String timeAgo;
  final double rating;
  final String comment;

  ReviewCard({
    required this.username,
    required this.timeAgo,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.account_circle,
              size: screenWidth * 0.1, color: Colors.grey[700]),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.01),
                _buildRatingStars(screenWidth, rating),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double screenWidth, double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating) {
        stars.add(Icon(Icons.star,
            color: Colors.yellow[700], size: screenWidth * 0.04));
      } else if (i - rating == 0.5) {
        stars.add(Icon(Icons.star_half,
            color: Colors.yellow[700], size: screenWidth * 0.04));
      } else {
        stars.add(Icon(Icons.star_border,
            color: Colors.yellow[700], size: screenWidth * 0.04));
      }
    }
    return Row(children: stars);  
  }
}
