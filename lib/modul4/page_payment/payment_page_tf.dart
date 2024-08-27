// payment_page_tf.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPageTf extends StatefulWidget {
  final List<Map<String, dynamic>> checkedItems;
  final int totalPrice;
  final String customerName;
  final String customerPhone;
  final String additionalNotes; // Tambahkan ini

  PaymentPageTf({
    required this.checkedItems,
    required this.totalPrice,
    required this.customerName,
    required this.customerPhone,
    required this.additionalNotes, // Tambahkan ini
  });

  @override
  _PaymentPageTfState createState() => _PaymentPageTfState();
}


final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _PaymentPageTfState extends State<PaymentPageTf> {
  @override
  void initState() {
    super.initState();
    _scheduleAutoDelete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          'Pembayaran Transfer Bank',
          style: TextStyle(
              color: Color(0xFF0B4D3B),
              fontSize: 25,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/bca-logo.png', // Ganti dengan path gambar logo BCA
                width: 200,
                height: 100,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Rekening BCA',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '1234567890',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Total Harga: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(widget.totalPrice)}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                child: Text('Konfirmasi Pembayaran'),
                onPressed: () {
                  _confirmPayment();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleAutoDelete() {
    Future.delayed(Duration(hours: 2), () async {
      var now = DateTime.now();
      var expiredDocs = await _firestore
          .collection('transaksiTemp')
          .where('timestamp', isLessThanOrEqualTo: now.subtract(Duration(hours: 2)))
          .get();

      for (var doc in expiredDocs.docs) {
        await _firestore.collection('transaksiTemp').doc(doc.id).delete();
      }

      for (var item in widget.checkedItems) {
        var cartSnapshot = await _firestore.collection('TestCart').where('productName', isEqualTo: item['productName']).get();
        if (cartSnapshot.docs.isNotEmpty) {
          var cartDoc = cartSnapshot.docs.first;
          await _firestore.collection('TestCart').doc(cartDoc.id).delete();
        }
      }
    });
  }

  Future<void> _confirmPayment() async {
    // Implementasi konfirmasi pembayaran transfer bank
    // Anda bisa menambahkan logika untuk mengupdate status transaksi di Firestore
  }
}
