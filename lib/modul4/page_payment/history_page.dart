import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modul1/login.dart';
import 'payment_page_history.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Login untuk melihat pesanan Anda'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Pesanan Saya",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transaksi')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, transaksiSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('transaksiTemp')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, transaksiTempSnapshot) {
              if (transaksiSnapshot.connectionState == ConnectionState.waiting ||
                  transaksiTempSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (transaksiSnapshot.hasError || transaksiTempSnapshot.hasError) {
                return const Center(child: Text("Error loading orders"));
              }
              if (!transaksiSnapshot.hasData &&
                  !transaksiTempSnapshot.hasData) {
                return const Center(child: Text("No orders found"));
              }

              var orders = [
                ...transaksiSnapshot.data!.docs,
                ...transaksiTempSnapshot.data!.docs,
              ];

              // Sort all orders by timestamp
              orders.sort((a, b) => (b['timestamp'] as Timestamp)
                  .compareTo(a['timestamp'] as Timestamp));

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var order = orders[index];
                  String status = order['status'];
                  String transactionId = order.id;
                  bool isTemp = order.reference.parent.id == 'transaksiTemp';

                  final data = order.data() as Map<String, dynamic>?;

                  if (data != null && data.containsKey('stores')) {
                    return _buildNewOrderFormat(context, order, status, transactionId, isTemp);
                  } else {
                    return _buildOldOrderFormat(context, order, status, transactionId, isTemp);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOldOrderFormat(BuildContext context, DocumentSnapshot order, String status, String transactionId, bool isTemp) {
    String productName = order['productName'] ?? 'Unknown Product';
    int productPrice = order['productPrice'] ?? 0;
    int quantity = order['quantity'] ?? 1;
    String productImage = order['productImage'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Makanan & Minuman',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(status),
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    productImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Warna hitam untuk harga per menu
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity pcs',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice * quantity)}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green, // Warna hijau untuk total harga
                  ),
                ),
                if (status != "cancel") // Sembunyikan tombol jika status "canceled"
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentHistoryPage(
                            transactionId: transactionId,
                            isTemp: isTemp,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == "completed" ? Colors.blue : Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      status == "completed" ? "Tulis Ulasan" : "Bayar",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewOrderFormat(BuildContext context, DocumentSnapshot order, String status, String transactionId, bool isTemp) {
    List<dynamic> stores = order['stores'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Makanan & Minuman',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(status),
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stores.map((store) {
                List<dynamic> items = store['items'] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    String productName = item.containsKey('productName') ? item['productName'] : 'Unknown Product';
                    int quantity = item.containsKey('quantity') ? item['quantity'] : 1;
                    String selectedOptions = item.containsKey('selectedOptions') && item['selectedOptions'].isNotEmpty 
                                              ? ' (${item['selectedOptions']})' 
                                              : '';
                    int productPrice = item.containsKey('productPrice') ? item['productPrice'] : 0;
                    String productImage = item.containsKey('productImage') ? item['productImage'] : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              productImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error);
                              },
                            ),
                          ),
                          SizedBox(width: 10), // Space between image and text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$productName x$quantity',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black, // Warna hitam untuk harga per menu
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedOptions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      selectedOptions,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(stores.fold<int>(0, (previousValue, store) {
                    return previousValue + (store['items'] as List<dynamic>).fold<int>(0, (previousValue, item) {
                      return previousValue + ((item['productPrice'] as int) * (item['quantity'] as int));
                    });
                  }))}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green, // Warna hijau untuk total harga
                  ),
                ),
                if (status != "cancel") // Sembunyikan tombol jika status "canceled"
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentHistoryPage(
                            transactionId: transactionId,
                            isTemp: isTemp,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == "completed" ? Colors.blue : Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      status == "completed" ? "Tulis Ulasan" : "Bayar",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case "completed":
        return "Selesai";
      case "cancel":
        return "Pembayaran Gagal";
      case "pending":
        return "Belum Bayar";
      default:
        return "Status Tidak Diketahui";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "completed":
        return Color(0xFFE3F2FD);
      case "cancel":
        return Color(0xFFFFEBEE);
      case "pending":
        return Color(0xFFFFF3E0);
      default:
        return Color(0xFFE0E0E0);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case "completed":
        return Color(0xFF1E88E5);
      case "cancel":
        return Color(0xFFD32F2F);
      case "pending":
        return Color(0xFFF57C00);
      default:
        return Colors.black;
    }
  }
}