import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PaymentHistoryPage extends StatefulWidget {
  final String transactionId;

  PaymentHistoryPage({required this.transactionId});

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;
  DateTime? _expiryTime;
  Map<String, dynamic>? transactionData;
  Map<String, List<Map<String, dynamic>>> storeItems = {}; // Menyimpan items per toko
  bool isLoading = true;
  bool hasExpired = false;
  String? _refId; // Tambahkan variabel untuk refId dari transaksi

  @override
  void initState() {
    super.initState();
    _fetchTransactionData();
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

  Future<void> _fetchTransactionData() async {
    try {
      // Mengambil dokumen dari koleksi 'transaction' berdasarkan transactionId
      DocumentSnapshot transactionDoc = await _firestore
          .collection('transaction')
          .doc(widget.transactionId)
          .get();

      if (transactionDoc.exists) {
        setState(() {
          transactionData = transactionDoc.data() as Map<String, dynamic>;
          _expiryTime = (transactionData!['expiryTime'] as Timestamp).toDate();
          _refId = transactionData!['refId']; // Mengambil refId dari transaksi
        });

        // Mengambil sub-koleksi 'items' untuk setiap store yang ada di field 'stores'
        List stores = transactionData!['stores'];
        for (var store in stores) {
          String storeId = store['storeId'];

          // Mengambil data dari sub-koleksi 'items' berdasarkan storeId
          DocumentSnapshot itemsDoc = await _firestore
              .collection('transaction')
              .doc(widget.transactionId)
              .collection('items')
              .doc(storeId)
              .get();

          if (itemsDoc.exists) {
            Map<String, dynamic> itemsData = itemsDoc.data() as Map<String, dynamic>;

            // Menyimpan items ke dalam struktur storeItems berdasarkan storeId
            setState(() {
              storeItems[storeId] = List<Map<String, dynamic>>.from(itemsData['products']);
            });
          }
        }

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transaction data: $e');
    }
  }

  void _checkExpiry() {
    if (_expiryTime != null) {
      final now = DateTime.now();
      final isExpired = now.isAfter(_expiryTime!);

      if (isExpired && !hasExpired) {
        setState(() {
          hasExpired = true;
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

    if (user != null) {
      await _firestore.collection('transaction').doc(widget.transactionId).update({'status': 'cancel'});

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
    }
  }

  // Logika untuk memulai pengecekan status pembayaran
  void _startPaymentStatusCheck() {
    const int checkInterval = 5; // Interval check setiap 5 detik
    _timer = Timer.periodic(Duration(seconds: checkInterval), (timer) async {
      if (hasExpired) {
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

  // Metode untuk mengecek status pembayaran
  Future<bool> _checkPaymentStatus() async {
    try {
      if (_refId != null) {
        final response = await http.post(
          Uri.parse('https://us-central1-long-flash-434811-b9.cloudfunctions.net/qris-api/api/checkPaymentStatus'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refId': _refId, // Gunakan refId dari transaksi
          }),
        );

        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return true; // Pembayaran sukses
        } 
      }
    } catch (e) {
    }
    return false;
  }

  // Metode yang dipanggil ketika pembayaran sukses
  Future<void> _onPaymentSuccess() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Query untuk menemukan dokumen dengan `refId` sebagai field
      QuerySnapshot querySnapshot = await _firestore
          .collection('transaction')
          .where('refId', isEqualTo: _refId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Jika dokumen ditemukan, ambil ID dokumen tersebut
        String docId = querySnapshot.docs.first.id;

        // Update status transaksi ke 'on-paid'
        await _firestore
            .collection('transaction')
            .doc(docId)
            .update({'status': 'on-paid'});

        // Tampilkan dialog sukses
        _showSuccessDialog();
      } else {
        // Jika tidak ditemukan, tangani error
        print('Transaction with refId $_refId not found');
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


  @override
  Widget build(BuildContext context) {
    if (isLoading || transactionData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pembayaran'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => BottomNavigation()),
            );
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
    );
  }

  Widget _buildTimeRemainingCard() {
    return Card(
      color: Colors.white,
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

  Widget _buildPaymentMethodCard() {
    return Card(
      color: Colors.white,
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
              child: transactionData?['qrisUrl'] != null
                  ? Column(
                      children: [
                        SizedBox(height: 8),
                        Image.network(
                          transactionData!['qrisUrl'],
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
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

    List<Widget> storeGroups = [];
    for (var store in transactionData?['stores'] ?? []) {
      String storeId = store['storeId'];
      List<Map<String, dynamic>> items = storeItems[storeId] ?? [];

      storeGroups.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toko: ${store['storeName'] ?? 'Unknown Store'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 16),
            Divider(),
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
                            if (item['selectedOptions'] != null &&
                                item['selectedOptions'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  item['selectedOptions'],
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
                        formatCurrency.format(item['productPrice'] * item['quantity']),
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
            Divider(),
          ],
        ),
      );
    }

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
            Divider(),
            ...storeGroups,
          ],
        ),
      ),
    );
  }

 Widget _buildTotalHargaCard() {
  final formatCurrency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  // Retrieve the subtotal, tax, and total price with tax from the transaction data
  final int subtotal = transactionData!['subtotal'];
  final int tax = transactionData!['tax'];
  final int totalPriceWithTax = transactionData!['totalPriceWithTax'];

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
                  color: Colors.black,
                ),
              ),
              Text(
                formatCurrency.format(subtotal),
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
                  color: Colors.black,
                ),
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
                  color: Colors.green,
                ),
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

}
