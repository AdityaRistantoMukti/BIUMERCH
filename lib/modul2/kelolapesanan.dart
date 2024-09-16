import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_box.dart';

class KelolaPesananScreen extends StatefulWidget {
  const KelolaPesananScreen({super.key});

  @override
  _KelolaPesananScreenState createState() => _KelolaPesananScreenState();
}

class _KelolaPesananScreenState extends State<KelolaPesananScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _orderStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching orders'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pesanan saat ini'));
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderBox(
                  imageUrl: order['product']['productImage'] ?? '',
                  namaBarang: order['product']['productName'] ?? 'Unknown Product',
                  namaPemesan: order['customerName'] ?? 'Unknown Customer',
                  totalPesanan: order['Subtotal']?.toString() ?? '0',
                  priceProduct: order['product']['productPrice']?.toString() ?? '0',
                  quantity: order['product']['quantity']?.toString() ?? '0',
                  status: order['product']['status'] ?? 'pending',
                  opsi: order['product']['selectedOptions'] ?? 'N/A',
                  catatan: order['catatanTambahan'] ?? 'Tidak ada catatan.',
                  jumlahPembayaran: order['Subtotal']?.toString() ?? '0',
                  transactionId: order['transactionId'] ?? '',
                  category: order['product']['category'],
                  storeId: order['storeId'] ?? '', // Tambahkan storeId
                );
              },
            );
          }
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _orderStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .asyncExpand((storeSnapshot) {
        if (storeSnapshot.docs.isNotEmpty) {
          String storeId = storeSnapshot.docs.first.id;
          return FirebaseFirestore.instance
              .collection('transaction')
              .where('status', isEqualTo: 'on-paid')
              .snapshots()
              .asyncMap((transactionSnapshot) async {
            List<Map<String, dynamic>> fetchedOrders = [];

            for (var transactionDoc in transactionSnapshot.docs) {
              List stores = transactionDoc['stores'] ?? [];
              bool storeInTransaction = stores.any((store) => store['storeId'] == storeId);

              if (storeInTransaction) {
                final itemsDoc = await FirebaseFirestore.instance
                    .collection('transaction')
                    .doc(transactionDoc.id)
                    .collection('items')
                    .doc(storeId)
                    .get();

                if (itemsDoc.exists) {
                  Map<String, dynamic> itemData = itemsDoc.data()!;
                  List<dynamic> products = itemData['products'] ?? [];
                  
                  for (var product in products) {
                    fetchedOrders.add({
                      'transactionId': transactionDoc.id,
                      'customerName': transactionDoc['customerName'] ?? 'Unknown',
                      'timestamp': transactionDoc['timestamp'] ?? 'Unknown',
                      'product': product,
                      'storeId': storeId,
                      ...itemData,
                    });
                  }
                }
              }
            }
            return fetchedOrders;
          });
        } else {
          return const Stream.empty();
        }
      });
    }
    return const Stream.empty();
  }
}
