import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart';

class PaymentPageQris extends StatefulWidget {
  final List<Map<String, dynamic>> checkedItems;
  final int totalPrice;
  final String customerName;
  final String customerPhone;
  final String additionalNotes;

  PaymentPageQris({
    required this.checkedItems,
    required this.totalPrice,
    required this.customerName,
    required this.customerPhone,
    required this.additionalNotes,
  });

  @override
  _PaymentPageQrisState createState() => _PaymentPageQrisState();
}

class _PaymentPageQrisState extends State<PaymentPageQris> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseStorage _storage = FirebaseStorage.instance;


  String? _qrisUrl;
  Timer? _timer;
  String? _refId;
  DateTime? _expiryTime;
  Map<String, String> _storeNames = {};
  bool isExpired = false;
String? _invoiceNumber; // Store this globally for further access

  @override
  void initState() {
    super.initState();
    _fetchStoreNames();
    _generateQris();
    _startPaymentStatusCheck();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
      _checkExpiry();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStoreNames() async {
    for (var item in widget.checkedItems) {
      String storeId = item['storeId'];
      if (!_storeNames.containsKey(storeId)) {
        DocumentSnapshot storeDoc =
            await _firestore.collection('stores').doc(storeId).get();
        if (storeDoc.exists && mounted) {
          setState(() {
            _storeNames[storeId] = storeDoc['storeName'];
          });
        }
      }
    }
  }

  Future<void> _generateQris() async {
  try {
    // Calculate tax (1.3% of totalPrice)
    final int tax = (widget.totalPrice * 0.013).toInt();
    final int totalPriceWithTax = widget.totalPrice + tax;

    // Generate QRIS using totalPriceWithTax
    final response = await http.post(
      Uri.parse('https://us-central1-long-flash-434811-b9.cloudfunctions.net/qris-api/api/generateQris'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'totalPrice': totalPriceWithTax, // Use totalPriceWithTax for QRIS generation
        'ref': DateTime.now().millisecondsSinceEpoch.toString(),
      }),
    );

    final responseData = jsonDecode(response.body);
    if (mounted) {
      setState(() {
        _qrisUrl = responseData['rawqr'];
        _refId = responseData['refid'];
        _expiryTime = DateTime.now().add(Duration(seconds: 16)); // Set expiry time for 2 minutes
      });
    }

    if (_qrisUrl != null) {
      await _saveQrisToStorage(_qrisUrl!, totalPriceWithTax); // Pass totalPriceWithTax to save method
    }
  } catch (e) {
    print('Error generating QRIS: $e');
  }
}

 Future<void> _saveQrisToStorage(String qrisUrl, int totalPriceWithTax) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    AuthenticationRepository.instance.logout();
    return;
  }

  try {
    // Generate QR code image and save to temporary storage
    final response = await http.get(Uri.parse(
        'https://api.qrserver.com/v1/create-qr-code/?data=$qrisUrl&size=200x200'));
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_refId.png');
    await file.writeAsBytes(response.bodyBytes);

    // Upload the QR code image to Firebase Storage
    final storageRef = _storage.ref().child('qris/${_refId}.png');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Get the current date for invoice formatting
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyyMMdd').format(now); // e.g., 20240910
    final String invoicePrefix = 'BMC-$formattedDate-';

    // Get the number of transactions for the day to create a unique invoice number
    QuerySnapshot transactionSnapshot = await _firestore
        .collection('transaction')
        .where('createdDate', isEqualTo: formattedDate)
        .get();

    int transactionCount = transactionSnapshot.size + 1;
    _invoiceNumber = '$invoicePrefix${transactionCount.toString().padLeft(4, '0')}'; // Store globally

    // Preparing store and items for the new structure
    Map<String, List<Map<String, dynamic>>> storeItems = {};
    Map<String, dynamic> storeInfo = {};

    for (var item in widget.checkedItems) {
      String storeId = item['storeId'];

      // Collect product details for each store
      if (!storeItems.containsKey(storeId)) {
        storeItems[storeId] = [];
      }
      storeItems[storeId]!.add({
        'productId': item['productId'],
        'productImage': item['productImage'],
        'productName': item['productName'],
        'category': item['category'],
        'status': 'waiting-store-confirmation',
        'productPrice': (item['productPrice'] as num).toInt(),
        'selectedOptions': item['selectedOption'] ?? '',
        'quantity': (item['quantity'] as num).toInt(),
        'timestamp': DateTime.now(),
        'totalPriceProduct': (item['productPrice'] as num).toInt() *
            (item['quantity'] as num).toInt(),
      });

      // Prepare store info for the main document
      storeInfo[storeId] = {
        'storeId': storeId,
        'storeName': _storeNames[storeId],
      };
    }

    // Save the main transaction document with the QR code, store info, and tax
    DocumentReference transactionRef = _firestore.collection('transaction').doc(_invoiceNumber);

    await transactionRef.set({
      'qrisUrl': downloadUrl,
      'customerName': widget.customerName,
      'customerPhone': widget.customerPhone,
      'status': 'pending',
      'subtotal': widget.totalPrice,
      'tax': totalPriceWithTax - widget.totalPrice,
      'totalPriceWithTax': totalPriceWithTax,
      'stores': storeInfo.values.toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': _expiryTime,
      'refId': _refId,
      'createdDate': formattedDate,
      'userId': user.uid,
    }, SetOptions(merge: true));

    // For each store, create a document under the 'items' subcollection with the storeId as the document ID
    for (var storeId in storeItems.keys) {
      await transactionRef.collection('items').doc(storeId).set({
        'products': storeItems[storeId],
        'timestamp': DateTime.now(),
        'Subtotal': storeItems[storeId]!
            .map((item) => item['totalPriceProduct'] as int)
            .reduce((a, b) => a + b),
        'catatanTambahan': widget.additionalNotes,
      });
    }
  } catch (e) {
    print('Error saving QRIS to storage: $e');
  }
}

Future<void> _onPaymentSuccess() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null && _invoiceNumber != null) {
    try {
      // Retrieve the document by invoiceNumber (the document ID)
      DocumentSnapshot transactionDoc = await _firestore.collection('transaction').doc(_invoiceNumber).get();

      if (transactionDoc.exists) {
        // Update the transaction status to 'on-paid'
        await _firestore.collection('transaction').doc(_invoiceNumber).update({'status': 'on-paid'});

        // Show success dialog
        _showSuccessDialog();
      } else {
        print('Transaction with invoiceNumber $_invoiceNumber not found');
      }
    } catch (e) {
      print('Error updating document: $e');
    }
  }
}

void _showSuccessDialog() {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext buildContext, Animation animation,
        Animation secondaryAnimation) {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Transaksi Anda telah berhasil dilakukan dan menunggu konfirmasi dari toko.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BottomNavigation(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      );
    },
  );
}

  void _checkExpiry() {
    if (_expiryTime != null) {
      final now = DateTime.now();
      final isExpired = now.isAfter(_expiryTime!);

      if (isExpired && !this.isExpired) {
        setState(() {
          this.isExpired = true;
        });
        _onPaymentTimeout();
      }
    }
  }

  String _formatTimeRemaining() {
    if (_expiryTime == null) return '00:00';

    final now = DateTime.now();
    final remaining = _expiryTime!.difference(now);

    if (remaining.isNegative) return '00:00';

    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Future<void> _onPaymentTimeout() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null && _invoiceNumber != null) {
    try {
      // Retrieve the document by invoiceNumber (the document ID)
      DocumentSnapshot transactionDoc = await _firestore.collection('transaction').doc(_invoiceNumber).get();

      if (transactionDoc.exists) {
        // Update the transaction status to 'cancel'
        await _firestore.collection('transaction').doc(_invoiceNumber).update({'status': 'cancel'});

        // Show timeout dialog
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waktu Pembayaran Habis',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Waktu untuk melakukan pembayaran telah habis. Pesanan Anda dibatalkan.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  child: Text('Oke', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          );
        }
      } else {
        print('Transaction with invoiceNumber $_invoiceNumber not found');
      }
    } catch (e) {
      print('Error updating document: $e');
    }
  }
}

  void _startPaymentStatusCheck() {
    const int checkInterval = 5; // Interval check setiap 5 detik
    _timer = Timer.periodic(Duration(seconds: checkInterval), (timer) async {
      if (isExpired) {
        timer.cancel();
        return;
      }

      final isSuccess = await _checkPaymentStatus();
      if (isSuccess) {
        timer.cancel();
        await _onPaymentSuccess();
      }
    });
  }

  Future<bool> _checkPaymentStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-long-flash-434811-b9.cloudfunctions.net/qris-api/api/checkPaymentStatus'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refId': _refId,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        return true;
      } else {
        print('Payment not successful');
        return false;
      }
    } catch (e) {
      print('Error checking payment status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return to previous page
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, true); // Same as onWillPop
            },
          ),
          title: Text(
            'Detail Pembayaran',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeRemainingCard(),
                _buildPaymentMethodCard(),
                _buildDetailPesananCard(),
                _buildTotalHargaCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildPaymentMethodCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  'QRIS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: _qrisUrl != null
                  ? Column(
                      children: [
                        SizedBox(height: 8),
                        Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?data=$_qrisUrl&size=200x200',
                          width: 200,
                          height: 200,
                        ),
                      ],
                    )
                  : CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPesananCard() {
    final formatCurrency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in widget.checkedItems) {
      String storeId = item['storeId'];
      if (!groupedItems.containsKey(storeId)) {
        groupedItems[storeId] = [];
      }
      groupedItems[storeId]!.add(item);
    }

    List<Widget> storeGroups = [];
    groupedItems.forEach((storeId, items) {
      storeGroups.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nama Toko:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _storeNames[storeId] ?? 'Unknown Store',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(
              color: Colors.black,
              thickness: 1.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          item['productImage'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['productName']} x${item['quantity']}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (item['selectedOption'] != null &&
                                item['selectedOption'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${item['selectedOption']}',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        formatCurrency
                            .format(item['productPrice'] * item['quantity']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Divider(
              color: Colors.black,
              thickness: 1.0,
            ),
            if (widget.additionalNotes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Catatan Tambahan:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(
                  widget.additionalNotes,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                  ),
                ),
              ),
              Divider(
                color: Colors.black,
                thickness: 1.0,
              ),
            ],
          ],
        ),
      );
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pesanan',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1.0,
            ),
            ...storeGroups,
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHargaCard() {
  final formatCurrency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  // Calculate tax (1.3% of totalPrice)
  final int tax = (widget.totalPrice * 0.013).toInt();
  final int totalPriceWithTax = widget.totalPrice + tax;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal :',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Text(
                formatCurrency.format(widget.totalPrice),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Tax (1.3%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pajak (1.3%) :',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Text(
                formatCurrency.format(tax),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Divider for clarity between subtotal/tax and total
          Divider(
            color: Colors.black,
            thickness: 1.0,
          ),
          SizedBox(height: 8),

          // Total Price with Tax
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Harga :',
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              Text(
                formatCurrency.format(totalPriceWithTax),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTimeRemainingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Waktu Tersisa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTimeRemaining(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Other UI-related methods such as _buildPaymentMethodCard, _buildDetailPesananCard, etc.
}
