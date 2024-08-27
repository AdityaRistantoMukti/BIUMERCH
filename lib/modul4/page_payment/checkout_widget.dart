import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page_qris.dart';
import '../../modul1/login.dart';

class CheckoutWidget extends StatefulWidget {
  final List<Map<String, dynamic>> checkedItems;
  final int totalPrice;

  CheckoutWidget({required this.checkedItems, required this.totalPrice});

  @override
  _CheckoutWidgetState createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  List<int> quantities = [];
  String paymentMethod = 'Pilih metode pembayaran';
  List<String> paymentMethods = ['Pilih metode pembayaran', 'QRIS'];
  String _additionalNotes = '';
  String customerName = '';
  String customerPhone = '';
  String customerEmail = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    quantities = widget.checkedItems.map((item) => (item['quantity'] as num).toInt()).toList();
    _checkLoginStatus(); // Memeriksa status login pengguna
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      _fetchCustomerInfo(); // Mengambil informasi pelanggan jika pengguna sudah login
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> _fetchCustomerInfo() async {
    if (_currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .get();
      if (docSnapshot.exists) {
        setState(() {
          customerName = docSnapshot.data()?['username'] ?? '';
          customerPhone = docSnapshot.data()?['phone'] ?? '';
          customerEmail = docSnapshot.data()?['email'] ?? '';
        });
      }
    }
  }

  Future<void> _showPaymentMethodError(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Color(0xFFFF0000)),
                SizedBox(width: 10),
                Text(
                  'Kesalahan',
                  style: TextStyle(
                    color: Color(0xFFFF0000),
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            Divider(
              color: Color(0xFFFF0000),
              thickness: 1.5,
            ),
          ],
        ),
        content: Text(
          'Anda harus memilih metode pembayaran terlebih dahulu',
          style: TextStyle(
            color: Color(0xFFFF0000),
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFFF0000),
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
                fontSize: 18,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        title: Text(
          'Ringkasan Pesanan',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomerInfoCard(
              name: customerName,
              phone: customerPhone,
              email: customerEmail,
            ),
            Container(
              height: 1,
              color: Colors.black,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.checkedItems.length,
              itemBuilder: (context, index) {
                var item = widget.checkedItems[index];
                int quantity = (item['quantity'] as num).toInt();
                int productPrice = (item['productPrice'] as num).toInt();

                return OrderSummary(
                  quantity: quantity,
                  productName: item['productName'],
                  productPrice: productPrice,
                  productImage: item['productImage'],
                  selectedOption: item['selectedOption'], // Pass selectedOption here
                  onQuantityChanged: (newQuantity) async {
                    setState(() {
                      quantities[index] = newQuantity;
                      item['quantity'] = newQuantity;
                    });
                    await _updateCartQuantity(item['productName'], newQuantity);
                    if (newQuantity == 0) {
                      bool confirm = await _showConfirmationDialog(context);
                      if (confirm) {
                        await _removeItemFromCart(item['productName']);
                      }
                    }
                  },
                );
              },
            ),
            Container(
              height: 1,
              color: Colors.black,
            ),
            AdditionalNotes(
              onNotesChanged: (notes) {
                setState(() {
                  _additionalNotes = notes;
                });
              },
            ),
            PaymentMethod(
              paymentMethod: paymentMethod,
              paymentMethods: paymentMethods,
              onPaymentMethodChanged: (newMethod) {
                setState(() {
                  paymentMethod = newMethod;
                });
              },
            ),
            TotalPrice(totalPrice: _calculateTotalPrice()),
            PayButton(
              onPressed: () async {
                if (paymentMethod == 'Pilih metode pembayaran') {
                  _showPaymentMethodError(context);
                  return;
                }

                bool confirmed = await _showOrderConfirmationDialog(context);
                if (confirmed) {
                  await _deleteCheckedItemsFromCart();
                  if (paymentMethod == 'QRIS') {
                    await Navigator.pushReplacement(
                      context,
                      _createRoute(PaymentPageQris(
                        checkedItems: widget.checkedItems,
                        totalPrice: _calculateTotalPrice(),
                        customerName: customerName,
                        customerPhone: customerPhone,
                        additionalNotes: _additionalNotes,
                      )),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
                  Text(
                    'Konfirmasi Penghapusan',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
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

  Future<void> _updateCartQuantity(String productName, int newQuantity) async {
    if (_currentUser != null) {
      var cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('Cart')
          .where('productName', isEqualTo: productName)
          .get();

      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .doc(doc.id)
            .update({'quantity': newQuantity});
      }
    }
  }

  Future<void> _removeItemFromCart(String productName) async {
    if (_currentUser != null) {
      var cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('Cart')
          .where('productName', isEqualTo: productName)
          .get();

      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .doc(doc.id)
            .delete();
      }
    }
  }

  Future<bool> _showOrderConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF62E703),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Konfirmasi',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF62E703),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Divider(
                  color: Color(0xFF62E703),
                  thickness: 2,
                ),
              ],
            ),
            content: Text(
              'Apakah anda sudah yakin dengan pesanan anda?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: Color(0xFF000000),
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
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF62E703),
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
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

Future<void> _deleteCheckedItemsFromCart() async {
  if (_currentUser != null) {
    for (var item in widget.checkedItems) {
      var cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('Cart')
          .where('productName', isEqualTo: item['productName'])
          .where('selectedOption', isEqualTo: item['selectedOption'])
          .get();
      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .doc(doc.id)
            .delete();
      }
    }
  }
}

  int _calculateTotalPrice() {
    int totalPrice = 0;
    for (var item in widget.checkedItems) {
      totalPrice += ((item['productPrice'] as num).toInt()) * ((item['quantity'] as num).toInt());
    }
    return totalPrice;
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class CustomerInfoCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;

  CustomerInfoCard({
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Table(
          columnWidths: {
            0: IntrinsicColumnWidth(),
            1: FixedColumnWidth(16),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                Text('Nama',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(' : ',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(name,
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito')),
              ],
            ),
            TableRow(
              children: [
                SizedBox(height: 8),
                SizedBox(height: 8),
                SizedBox(height: 8),
              ],
            ),
            TableRow(
              children: [
                Text('No. telpon',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(' : ',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(phone,
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito')),
              ],
            ),
            TableRow(
              children: [
                SizedBox(height: 8),
                SizedBox(height: 8),
                SizedBox(height: 8),
              ],
            ),
            TableRow(
              children: [
                Text('Email',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(' : ',
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                Text(email,
                    style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 16,
                        fontFamily: 'Nunito')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSummary extends StatelessWidget {
  final int quantity;
  final String productName;
  final int productPrice;
  final String productImage;
  final String? selectedOption; // Add selectedOption as a parameter
  final ValueChanged<int> onQuantityChanged;

  OrderSummary({
    required this.quantity,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.onQuantityChanged,
    this.selectedOption, // Initialize selectedOption
  });

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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                productImage,
                width: 100,
                height: 100,
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
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  if (selectedOption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        selectedOption!,
                        style: TextStyle(
                          fontSize: 16, // Smaller font size for selectedOption
                          fontFamily: 'Nunito',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  SizedBox(height: 5),
                  Text(
                    'Rp. ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 10),
                  // Add quantity buttons here
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () async {
                          if (quantity > 1) {
                            onQuantityChanged(quantity - 1);
                          } else {
                            bool confirm = await _showConfirmationDialog(context);
                            if (confirm) {
                              onQuantityChanged(0);
                            }
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          onQuantityChanged(quantity + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}



class AdditionalNotes extends StatefulWidget {
  final ValueChanged<String> onNotesChanged;

  const AdditionalNotes({super.key, required this.onNotesChanged});

  @override
  _AdditionalNotesState createState() => _AdditionalNotesState();
}

class _AdditionalNotesState extends State<AdditionalNotes> {
  String _notes = '';

  void _showNotesDialog() async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController(text: _notes);
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F8F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Isi Catatan Tambahan',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Catatan: Bagian paha atas, sambal di pisah',
              hintStyle: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: 'Nunito',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFE3E3E3),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 45),
                    backgroundColor: const Color(0xFF707070),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(width: 5),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 45),
                    backgroundColor: const Color(0xFF62E703),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(controller.text);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _notes = result;
      });
      widget.onNotesChanged(_notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE3E3E3),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Catatan Tambahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _showNotesDialog,
              child: AbsorbPointer(
                child: TextField(
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _notes.isEmpty
                        ? 'Catatan: Bagian paha atas, sambal di pisah'
                        : _notes,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethod extends StatelessWidget {
  final String paymentMethod;
  final List<String> paymentMethods;
  final ValueChanged<String> onPaymentMethodChanged;

  PaymentMethod({
    required this.paymentMethod,
    required this.paymentMethods,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: const Color(0xFF707070),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              filled: true,
              fillColor: Color(0xFF707070),
            ),
            isExpanded: true,
            value: paymentMethod,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: const Color(0xFF707070),
            items: paymentMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(
                  method,
                  style:
                      const TextStyle(color: Colors.white, fontFamily: 'bold'),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onPaymentMethodChanged(newValue);
              }
            },
          ),
        ),
      ),
    );
  }
}

class TotalPrice extends StatelessWidget {
  final int totalPrice;

  TotalPrice({required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Harga:',
              style: TextStyle(fontSize: 16, fontFamily: 'Nunito')),
          Text(formatCurrency.format(totalPrice),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class PayButton extends StatelessWidget {
  final VoidCallback onPressed;

  PayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      child: ElevatedButton(
        child: Text('Bayar Pesanan',
            style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF62E703),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
