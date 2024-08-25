import 'package:biumerch_mobile_app/chat_penjual_page.dart';
import 'package:biumerch_mobile_app/page_payment/cart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodDetailPage extends StatefulWidget {
  final ImageProvider image;
  final String title;
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
  });

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  String? _selectedOption;
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
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HalamanChatPenjual()),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.shopping_cart,
                          color: Colors.grey[700], size: screenWidth * 0.07),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => KeranjangPage()),
                        );
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

  Widget _buildBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              child: Column(
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
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                            Divider(
                                color: Colors.grey[300], thickness: 1),
                            SizedBox(height: screenWidth * 0.05),
                            Text(
                              "Opsi :",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildOptionButton(setState, "Paha Atas"),
                                _buildOptionButton(setState, "Paha Bawah"),
                                _buildOptionButton(setState, "Kulit Ayam"),
                              ],
                            ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _addToCart(); // Menyimpan data ke Firestore
                        Navigator.of(context).pop();
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
            );
          },
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
