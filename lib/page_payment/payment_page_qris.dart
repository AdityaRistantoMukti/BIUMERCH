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
import '../login.dart'; // Import the login page
import 'cart.dart';

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
  String _authToken = '';
  Timer? _timer;
  String? _refId;
  int _remainingTime = 0;
  DateTime? _expiryTime;
  Map<String, String> _storeNames = {};

  @override
  void initState() {
    super.initState();
    _initializeAuthToken();
    _fetchStoreNames();
    _generateQris();
    _startTimer();
    _startPaymentStatusCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuthToken() async {
    String cid = '7b8c77e0ba26c849eb37532539bd38b9';
    String sk = '0a24c0a8c2696103b161427637107b23';
    String mid = '240726002000000';
    setState(() {
      _authToken = 'Bearer ${base64Encode(utf8.encode('$cid:$sk:$mid'))}';
    });
  }

  Future<void> _fetchStoreNames() async {
    for (var item in widget.checkedItems) {
      String storeId = item['storeId'];
      if (!_storeNames.containsKey(storeId)) {
        DocumentSnapshot storeDoc = await _firestore.collection('stores').doc(storeId).get();
        if (storeDoc.exists) {
          setState(() {
            _storeNames[storeId] = storeDoc['storeName'];
          });
        }
      }
    }
  }

  Future<void> _generateQris() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.paydia.id/qris/generate/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': _authToken,
        },
        body: jsonEncode({
          'merchantid': '240726002000000',
          'nominal': widget.totalPrice,
          'tip': 0,
          'ref': DateTime.now().millisecondsSinceEpoch.toString(),
          'callback': 'https://valiant-wonder.railway.app',
          'expire': 20,
        }),
      );

      final responseData = jsonDecode(response.body);
      setState(() {
        _qrisUrl = responseData['rawqr'];
        _refId = responseData['refid'];
        _expiryTime = DateTime.now().add(Duration(minutes: 20));
      });

      if (_qrisUrl != null) {
        await _saveQrisToStorage(_qrisUrl!);
      }
    } catch (e) {
      print('Error generating QRIS: $e');
    }
  }
Future<void> _saveQrisToStorage(String qrisUrl) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
    return;
  }

  try {
    final response = await http.get(Uri.parse(
        'https://api.qrserver.com/v1/create-qr-code/?data=$qrisUrl&size=200x200'));
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_refId.png');
    await file.writeAsBytes(response.bodyBytes);

    final storageRef = _storage.ref().child('qris/${_refId}.png');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Group items by storeId
    Map<String, Map<String, dynamic>> storeData = {};

    for (var item in widget.checkedItems) {
      String storeId = item['storeId'];
      if (storeData[storeId] == null) {
        storeData[storeId] = {
          'storeId': storeId,
          'storeName': _storeNames[storeId],
          'catatanTambahan': widget.additionalNotes,
          'items': [],
        };
      }

      storeData[storeId]!['items'].add({
  'productImage': item['productImage'],
  'productName': item['productName'],
  'productPrice': (item['productPrice'] as num).toInt(), // Ensure it's an int
  'selectedOptions': item['selectedOption'] ?? '',
  'quantity': (item['quantity'] as num).toInt(), // Ensure it's an int
  'timestamp': DateTime.now(), // Replace FieldValue.serverTimestamp() with DateTime.now()
  'totalHarga': (item['productPrice'] as num).toInt() * (item['quantity'] as num).toInt(), // Calculate total price
});

    }

    // Convert map to list for Firestore
    List<Map<String, dynamic>> storeList = storeData.values.toList();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transaksiTemp')
        .doc(_refId)
        .set({
      'qrisUrl': downloadUrl,
      'status': 'pending',
      'customerName': widget.customerName,
      'customerPhone': widget.customerPhone,
      'totalPrice': widget.totalPrice,
      'stores': storeList, // Store the store data as a list
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': _expiryTime,
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error saving QRIS to storage: $e');
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
        if (mounted) {
          _onPaymentTimeout();
        }
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
        await _onPaymentTimeout();
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
        Uri.parse('https://api.paydia.id/qris/check-status/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': _authToken,
        },
        body: jsonEncode({
          'refid': _refId,
        }),
      );

      final responseData = jsonDecode(response.body);
      return responseData['status'] == 'success';
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
        .doc(_refId)
        .update({'status': 'completed'});

    var transaksiTempDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transaksiTemp')
        .doc(_refId)
        .get();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transaksi')
        .doc(_refId)
        .set(transaksiTempDoc.data()!);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transaksiTemp')
        .doc(_refId)
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
                    'Transaksi Anda telah berhasil dilakukan. Terima kasih atas kepercayaan Anda.',
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
          .doc(_refId)
          .update({'status': 'cancel'});

      var transaksiTempDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(_refId)
          .get();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksi')
          .doc(_refId)
          .set(transaksiTempDoc.data()!);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transaksiTemp')
          .doc(_refId)
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => KeranjangPage(),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => KeranjangPage(),
                ),
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

  // Grouping items by storeId
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
                          if (item['selectedOption'] != null && item['selectedOption'].isNotEmpty)
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
                          formatCurrency.format(widget.totalPrice),
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
