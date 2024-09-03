import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String transactionId;
  final bool isTemp;

  PaymentHistoryPage({required this.transactionId, required this.isTemp});

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;
  int _remainingTime = 0;
  DateTime? _expiryTime;
  Map<String, dynamic>? transactionData;
  Map<String, String> _storeNames = {};

  @override
  void initState() {
    super.initState();
    _fetchTransactionData();
    _fetchStoreNames();
    _startTimer();
    _startPaymentStatusCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTransactionData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AuthenticationRepository.instance.logout();
      return;
    }

    var collection = widget.isTemp ? 'transaksiTemp' : 'transaksi';
    var doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collection)
        .doc(widget.transactionId)
        .get();

    if (doc.exists) {
      setState(() {
        transactionData = doc.data();
        _expiryTime = (transactionData!['expiryTime'] as Timestamp).toDate();
      });
    }
  }

  Future<void> _fetchStoreNames() async {
    if (transactionData != null) {
      for (var store in transactionData!['stores']) {
        String storeId = store['storeId'];
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
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await _calculateRemainingTime();

      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          _onPaymentTimeout();
        }
      }
    });
  }

  Future<void> _calculateRemainingTime() async {
    if (_expiryTime != null) {
      var currentTime = DateTime.now();
      var diff = _expiryTime!.difference(currentTime).inSeconds;

      if (diff > 0) {
        if (mounted) {
          setState(() {
            _remainingTime = diff;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = 0;
          });
        }
        _onPaymentTimeout();
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startPaymentStatusCheck() {
    const int checkInterval = 3;
    int elapsed = 0;

    _timer = Timer.periodic(Duration(seconds: checkInterval), (timer) async {
      elapsed += checkInterval;
      if (elapsed >= _remainingTime) {
        timer.cancel();
        if (mounted) {
          _onPaymentTimeout();
        }
        return;
      }

      final isSuccess = await _checkPaymentStatus();
      if (isSuccess) {
        timer.cancel();
        if (mounted) {
          _onPaymentSuccess();
        }
      }
    });
  }

  Future<bool> _checkPaymentStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://sixth-island-hair.glitch.me/api/checkPaymentStatus'), // Update URL sesuai dengan Glitch URL
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refId': widget.transactionId, // pastikan 'refid' di server.js sesuai dengan 'refId' di Flutter
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

  Future<void> _onPaymentSuccess() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .update({'status': 'waiting-store-confirmation'});

      var transaksiTempDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .get();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksi')
          .doc(widget.transactionId)
          .set(transaksiTempDoc.data()!);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .delete();

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
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
                        Navigator.of(context).popUntil((route) => route.isFirst);
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
  }

  Future<void> _onPaymentTimeout() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .update({'status': 'cancel'});

      var transaksiTempDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .get();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksi')
          .doc(widget.transactionId)
          .set(transaksiTempDoc.data()!);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(widget.transactionId)
          .delete();

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

  @override
  Widget build(BuildContext context) {
    if (transactionData == null) {
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
              _buildDetailPesananCard(),  // This method is used for detailed order view
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
                _formatTime(_remainingTime),
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
    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(store['items']);

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
                store['storeName'] ?? 'Unknown Store',
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
          Divider(
            color: Colors.black,
            thickness: 1.0,
          ),
          if (store['catatanTambahan'] != null &&
              store['catatanTambahan'].isNotEmpty) ...[
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
                store['catatanTambahan'],
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        'Total Harga :',
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency.format(transactionData!['totalPrice']),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
