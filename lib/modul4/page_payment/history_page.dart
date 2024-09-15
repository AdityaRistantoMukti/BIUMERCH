import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'payment_page_history.dart';
import '/modul1.2/data/repositories/authentication/authentication_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'ulasan.dart'; // Import the review page

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              AuthenticationRepository.instance.logout();
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Login untuk melihat pesanan Anda', style: TextStyle(fontSize: 16, color: Colors.green)),
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
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: _getCombinedStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          List<DocumentSnapshot> orders = [];
          for (var querySnapshot in snapshot.data!) {
            orders.addAll(querySnapshot.docs);
          }

          orders.sort((a, b) {
            Timestamp? timestampA = a['timestamp'] as Timestamp?;
            Timestamp? timestampB = b['timestamp'] as Timestamp?;
            if (timestampA != null && timestampB != null) {
              return timestampB.compareTo(timestampA);
            }
            return 0; // If either timestamp is null, consider them equal
          });

          for (var doc in orders) {
            _checkAndCancelExpiredTransaction(doc);
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              String status = order['status'];
              String transactionId = order.id;
              bool isTemp = order.reference.parent.id == 'transaksiTemp';

              final data = order.data() as Map<String, dynamic>?;

              if (data != null && data.containsKey('stores')) {
                return _buildNewOrderFormat(
                    context, order, status, transactionId, isTemp);
              } else {
                return _buildOldOrderFormat(
                    context, order, status, transactionId, isTemp);
              }
            },
          );
        },
      ),
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedStream(String userId) {
    final transaksiStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transaksi')
        .orderBy('timestamp', descending: true)
        .snapshots();

    final transaksiTempStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transaksiTemp')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return CombineLatestStream.list([transaksiStream, transaksiTempStream]);
  }

  Future<void> _checkAndCancelExpiredTransaction(DocumentSnapshot order) async {
    String status = order['status'];
    DateTime? expiryTime = order['expiryTime']?.toDate();

    if (expiryTime != null && status == 'pending') {
      if (DateTime.now().isAfter(expiryTime)) {
        await _updateStatus(order, 'cancel', true);
      }
    }
  }

  Future<void> _updateStatus(DocumentSnapshot order, String newStatus, bool isTemp) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      final collection = isTemp ? 'transaksiTemp' : 'transaksi';

      try {
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection(collection)
            .doc(order.id)
            .update({'status': newStatus});

        if (isTemp) {
          var tempData = await firestore
              .collection('users')
              .doc(user.uid)
              .collection('transaksiTemp')
              .doc(order.id)
              .get();

          if (tempData.exists) {
            await firestore
                .collection('users')
                .doc(user.uid)
                .collection('transaksi')
                .doc(order.id)
                .set(tempData.data()!);

            await firestore
                .collection('users')
                .doc(user.uid)
                .collection('transaksiTemp')
                .doc(order.id)
                .delete();
          } else {
            print('Data tidak ditemukan di transaksiTemp');
          }
        }
      } catch (e) {
        print('Error updating status or moving data: $e');
      }
    }
  }

  Widget _buildOldOrderFormat(BuildContext context, DocumentSnapshot order, String status, String transactionId, bool isTemp) {
    String productName = order['productName'] ?? 'Unknown Product';
    int productPrice = order['productPrice'] ?? 0;
    int quantity = order['quantity'] ?? 1;
    String productImage = order['productImage'] ?? 'https://via.placeholder.com/60';
    String productId = order['productId'] ?? 'unknown_product';
    String storeId = order['storeId'] ?? 'unknown_store';
    bool hasReview = order['review'] ?? false;

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
            // Order details display code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Makanan & Minuman',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                              color: Colors.black,
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
                    color: Colors.green,
                  ),
                ),
                if (status == "pending")
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
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Bayar",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (status == "completed" && !hasReview)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewPage(
                            transactionId: transactionId,
                            stores: [
                              {
                                'storeId': storeId,
                                'items': [
                                  {
                                    'productId': productId,
                                    'productName': productName,
                                    'quantity': quantity,
                                    'productPrice': productPrice,
                                    'productImage': productImage,
                                  }
                                ]
                              }
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Tulis Ulasan",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (status == "completed-delivery")
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context, order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Konfirmasi Pesanan",
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

  Future<void> _showConfirmationDialog(BuildContext context, DocumentSnapshot order) async {
    final data = order.data() as Map<String, dynamic>?;

    if (data != null) {
      String productName = data['productName'] ?? 'Produk';
      int totalPrice = data['totalPrice'] ?? 0;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Konfirmasi Pesanan",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: "Konfirmasi pesanan "),
                  TextSpan(
                    text: "$productName",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: " dan serahkan Rp "),
                  TextSpan(
                    text: "${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalPrice)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  TextSpan(text: " kepada toko."),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection(order.reference.parent.id)
                      .doc(order.id)
                      .update({
                        'status': 'completed',
                        'review': false // Add the review field and set it to false initially
                      });

                  Navigator.of(context).pop();
                },
                child: Text("Konfirmasi"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      );
    } else {
      print("No data found in the document.");
    }
  }

  Widget _buildNewOrderFormat(BuildContext context, DocumentSnapshot order, String status, String transactionId, bool isTemp) {
    List<dynamic> stores = order['stores'] ?? [];
final data = order.data() as Map<String, dynamic>?;

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
                Expanded(
                  child: Text(
                    'Makanan & Minuman',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                    String productName = item['productName'] ?? 'Unknown Product';
                    int quantity = item['quantity'] ?? 1;
                    String selectedOptions = item['selectedOptions'] != null && item['selectedOptions'].isNotEmpty
                        ? ' (${item['selectedOptions']})'
                        : '';
                    int productPrice = item['productPrice'] ?? 0;
                    String productImage = item['productImage'] ?? '';
                    String productId = item['productId'] ?? 'unknown_product';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$productName x$quantity',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
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
                Expanded(
                  child: Text(
                    'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(stores.fold<int>(0, (previousValue, store) {
                      return previousValue + (store['items'] as List<dynamic>).fold<int>(0, (previousValue, item) {
                        return previousValue + ((item['productPrice'] as int) * (item['quantity'] as int));
                      });
                    }))}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status == "pending")
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
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Bayar",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
if (status == "completed" && (data?['review'] ?? false) != true)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewPage(
                            transactionId: transactionId,
                            stores: stores.map((store) {
                              return {
                                'storeId': store['storeId'] ?? 'unknown_store',
                                'items': store['items'].map((item) {
                                  return {
                                    'productId': item['productId'] ?? 'unknown_product',
                                    'productName': item['productName'] ?? 'Unknown Product',
                                    'quantity': item['quantity'] ?? 1,
                                    'productPrice': item['productPrice'] ?? 0,
                                    'productImage': item['productImage'] ?? 'https://via.placeholder.com/60',
                                  };
                                }).toList(),
                              };
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Tulis Ulasan",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (status == "completed-delivery")
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context, order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Konfirmasi Pesanan",
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
      case "waiting-store-confirmation":
        return "Menunggu Konfirmasi Toko";
      case "is-preparing":
        return "Pesanan Sedang Dipersiapkan";
      case "declined-by-store":
        return "Ditolak oleh Toko";
      case "in-delivery":
        return "Dalam Pengiriman";
      case "completed-delivery":
        return "Pesanan Terkirim";
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
      case "waiting-store-confirmation":
        return Color(0xFFE3F2FD);
      case "is-preparing":
        return Color(0xFFFFF3E0);
      case "declined-by-store":
        return Color(0xFFFFEBEE);
      case "in-delivery":
        return Color(0xFFE3F2FD);
      case "completed-delivery":
        return Color(0xFFE3F2FD);
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
      case "waiting-store-confirmation":
        return Color(0xFF1E88E5);
      case "is-preparing":
        return Color(0xFFF57C00);
      case "declined-by-store":
        return Color(0xFFD32F2F);
      case "in-delivery":
        return Color(0xFF1E88E5);
      case "completed-delivery":
        return Color(0xFF1E88E5);
      default:
        return Colors.black;
    }
  }
}
