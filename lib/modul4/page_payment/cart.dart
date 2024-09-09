import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart'; // Ganti impor untuk autentikasi
import 'checkout_widget.dart';
import 'package:intl/intl.dart';

class KeranjangPage extends StatefulWidget {
  @override
  _KeranjangPageState createState() => _KeranjangPageState();
}
class _KeranjangPageState extends State<KeranjangPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
 List<bool> isCheckedList = [];
  // Gunakan ValueNotifier untuk totalPrice
  final ValueNotifier<int> _totalPrice = ValueNotifier<int>(0);
  String _additionalNotes = '';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  User? _currentUser;
  String _sortOption = 'default';
  String? _selectedStoreId;


  @override
  bool get wantKeepAlive => true;

   @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    _animationController.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _totalPrice.dispose(); // Pastikan untuk membuang ValueNotifier
    super.dispose();
  }

Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    } else {
      await AuthenticationRepository.instance.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }
return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Keranjang Saya',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Color(0xFF000000),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Image.asset('assets/images/filter.png'),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
     body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); 

          }
          if (snapshot.hasError) {
            return 
 Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: 
 Text('Keranjang kosong'));
          }

          var productDocs = snapshot.data!.docs;

          _applySortingAndFiltering(productDocs);

          if (isCheckedList.length != productDocs.length) {
            isCheckedList = List<bool>.filled(productDocs.length, false);
          }

          _calculateTotalPrice(productDocs);


          return Stack(
            children: [
              ListView.builder(
                key: ValueKey<int>(productDocs.length),
                padding: EdgeInsets.only(bottom: 150),
                itemCount: productDocs.length,
                itemBuilder: (context, index) =>
                    _buildProductItem(productDocs[index], index, productDocs),
              ),
 ValueListenableBuilder<int>(
                valueListenable: _totalPrice,
                builder: (context, totalPrice, _) {
return totalPrice > 0 ? _buildTotalPriceWidget(productDocs) : SizedBox.shrink();                },
              ),
            ],
          );
        },
      ),
    );
  }
  void _applySortingAndFiltering(List<QueryDocumentSnapshot> productDocs) {
    if (_sortOption == 'price_asc') {
      productDocs.sort((a, b) => (a['productPrice'] as num).compareTo(b['productPrice'] as num));
    } else if (_sortOption == 'price_desc') {
      productDocs.sort((a, b) => (b['productPrice'] as num).compareTo(a['productPrice'] as num));
    }

    if (_selectedStoreId != null) {
      productDocs.removeWhere((doc) => doc['storeId'] != _selectedStoreId);
    }
  }
 void _calculateTotalPrice(List<QueryDocumentSnapshot> productDocs) {
    int newTotalPrice = 0;
    for (int i = 0; i < productDocs.length; i++) {
      if (isCheckedList[i]) {
        newTotalPrice += ((productDocs[i]['productPrice'] as num).toInt()) *
            ((productDocs[i]['quantity'] as num).toInt());
      }
    }
    _totalPrice.value = newTotalPrice; // Perbarui nilai totalPrice melalui ValueNotifier
  }
Widget _buildProductItem(QueryDocumentSnapshot productDoc, int index, List<QueryDocumentSnapshot> productDocs) { 
  String productName = productDoc['productName'] ?? '';
  int productPrice = (productDoc['productPrice'] as num).toInt();
  String productImage = productDoc['productImage'] ?? '';
  int quantity = (productDoc['quantity'] as num).toInt();

  return StatefulBuilder( // Bungkus setiap item dengan StatefulBuilder
    builder: (context, setState) {
      return SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Color(0xFFF4F4F4),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    productImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (productDoc['selectedOption'] != null)
                        Text(
                          productDoc['selectedOption'],
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Color(0xFF319F43),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Transform.translate(
                        offset: Offset(23, -18),
                        child: Transform.scale(
                          scale: 1,
                         child: Checkbox(
            value: isCheckedList[index],
            onChanged: (value) {
              setState(() {
                isCheckedList[index] = value!;
                _calculateTotalPrice(productDocs);
              });
            },
                            activeColor: Color(0xFF60cac0),
                            side: BorderSide(
                              color: Colors.black,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityButton(Icons.remove, () async {
                          if (quantity > 1) {
                            _updateCartQuantity(productDoc.id, quantity - 1);
                          } else {
                            bool confirm = await _showConfirmationDialog(context);
                            if (confirm) {
                              _removeItemFromCart(productDoc.id);
                            }
                          }
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildQuantityButton(Icons.add, () {
                          _updateCartQuantity(productDoc.id, quantity + 1);
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  Widget _buildTotalPriceWidget(List<QueryDocumentSnapshot> productDocs) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Harga:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                  ),
                ),
                Text(
            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(_totalPrice.value)}', // Gunakan _totalPrice.value
            style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Center(
                child: Text(
                  'Pesan Sekarang',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF62E703),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                minimumSize: Size(200, 50),
              ),
              onPressed: () async {
                var checkedItems = _getCheckedItems(productDocs);
                await Navigator.push(
                  context,
                  _createRoute(CheckoutWidget(
      checkedItems: checkedItems,
      totalPrice: _totalPrice.value, // Gunakan _totalPrice.value
      additionalNotes: _additionalNotes,
    )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCheckedItems(List<QueryDocumentSnapshot> productDocs) {
    return List.generate(
      isCheckedList.length,
      (index) => isCheckedList[index]
          ? {
              'productId': productDocs[index]['productId'],
              'productName': productDocs[index]['productName'],
              'productPrice': productDocs[index]['productPrice'],
              'productImage': productDocs[index]['productImage'],
              'quantity': productDocs[index]['quantity'],
              'category': productDocs[index]['category'],
              'selectedOption': productDocs[index]['selectedOption'],
              'storeId': productDocs[index]['storeId'],
            }
          : null,
    ).whereType<Map<String, dynamic>>().toList();
  }

Future<Map<String, String>> _getUniqueStores() async {
    var cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Cart')
        .get();
    
    Map<String, String> uniqueStores = {};
    for (var doc in cartSnapshot.docs) {
      String storeId = doc['storeId'] as String;
      if (!uniqueStores.containsKey(storeId)) {
        // Fetch store name from 'stores' collection
        var storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        
        if (storeDoc.exists) {
          String storeName = storeDoc.data()?['storeName'] ?? 'Unknown Store';
          uniqueStores[storeId] = storeName;
        }
      }
    }
    return uniqueStores;
  }
void _showFilterDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white, // Use white for the background, consistent with other dialogs
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Consistent with other dialogs
            ),
            title: Text(
              'Filter dan Urutan',
              style: TextStyle(
                fontSize: 20, // Matching the font size from the confirmation dialog
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Same color as the other dialogs
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urutkan berdasarkan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Consistent text color
                  ),
                ),
                RadioListTile(
                  title: Text(
                    'Default',
                    style: TextStyle(color: Colors.black87), // Matching text color
                  ),
                  value: 'default',
                  groupValue: _sortOption,
                  activeColor: Colors.green, // Consistent green color for active radio buttons
                  onChanged: (value) {
                    setState(() => _sortOption = value.toString());
                  },
                ),
                RadioListTile(
                  title: Text(
                    'Harga Termurah',
                    style: TextStyle(color: Colors.black87),
                  ),
                  value: 'price_asc',
                  groupValue: _sortOption,
                  activeColor: Colors.green, // Consistent green
                  onChanged: (value) {
                    setState(() => _sortOption = value.toString());
                  },
                ),
                RadioListTile(
                  title: Text(
                    'Harga Termahal',
                    style: TextStyle(color: Colors.black87),
                  ),
                  value: 'price_desc',
                  groupValue: _sortOption,
                  activeColor: Colors.green, // Consistent green
                  onChanged: (value) {
                    setState(() => _sortOption = value.toString());
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Filter Toko:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Consistent text color
                  ),
                ),
                FutureBuilder<Map<String, String>>(
                  future: _getUniqueStores(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(
                        color: Colors.green, // Consistent green color for loading indicator
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        'Tidak ada toko tersedia',
                        style: TextStyle(color: Colors.black87),
                      );
                    }
                    return DropdownButton<String>(
                      value: _selectedStoreId,
                      hint: Text(
                        'Pilih Toko',
                        style: TextStyle(color: Colors.black87),
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Toko'),
                        ),
                        ...snapshot.data!.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStoreId = value);
                      },
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.black87, // Consistent black text for the button
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  this.setState(() {}); // Trigger a rebuild of the main widget
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.green, // Consistent green button background
                ),
                child: Text(
                  'Terapkan',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // White text, consistent with other dialogs
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _updateCartQuantity(String docId, int newQuantity) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Cart')
        .doc(docId)
        .update({'quantity': newQuantity});
  }

  void _removeItemFromCart(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Cart')
        .doc(docId)
        .delete();
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Konfirmasi Penghapusan',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Apakah Anda yakin ingin menghapus item ini?',
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
                    'Tidak',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFFF0000),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ya',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

}