import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';

class OrderList extends StatelessWidget {
  final Stream<List<QuerySnapshot>> combinedStream;
  final TabController tabController;

  const OrderList({
    required this.combinedStream,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: combinedStream,
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

        QuerySnapshot transactionSnapshot = snapshot.data![0];
        List<QuerySnapshot> itemsSnapshots = snapshot.data!.sublist(1);

        List<DocumentSnapshot> orders = transactionSnapshot.docs;
        orders.sort((a, b) {
          return (b['timestamp'] as Timestamp).compareTo(a['timestamp']);
        });

        return TabBarView(
          key: ValueKey<int>(tabController.index),
          controller: tabController,
          children: [
            _buildFilteredOrderList(orders, itemsSnapshots, ['pending'], "transaction"), // Belum Bayar
            _buildFilteredOrderList(orders, itemsSnapshots, ['on-paid'], "product", ['waiting-store-confirmation', 'is-preparing']), // Dipersiapkan
            _buildFilteredOrderList(orders, itemsSnapshots, ['on-paid'], "product", ['in-delivery']), // Dikirim
            _buildFilteredOrderList(orders, itemsSnapshots, ['on-paid'], "product", ['completed-delivery', 'completed']), // Selesai
            _buildFilteredOrderList(orders, itemsSnapshots, ['cancel', 'canceled-by-user'], "transaction"), // Dibatalkan
          ],
        );
      },
    );
  }

  Widget _buildFilteredOrderList(
      List<DocumentSnapshot> orders, 
      List<QuerySnapshot> itemsSnapshots, 
      List<String> filterStatuses, 
      String statusType, 
      [List<String>? productFilterStatuses]) {

    List<Widget> orderWidgets = [];

    for (int i = 0; i < orders.length; i++) {
      DocumentSnapshot order = orders[i];
      QuerySnapshot itemsSnapshot = itemsSnapshots[i];

      Map<String, dynamic> orderData = order.data() as Map<String, dynamic>;
      String transactionStatus = orderData['status'] ?? 'Unknown';
      Timestamp? expirationTime = orderData['expirationTime'] as Timestamp?;

      // Check if the transaction has expired, if so, move to "cancel"
      if (expirationTime != null && expirationTime.toDate().isBefore(DateTime.now()) && transactionStatus == 'pending') {
        FirebaseFirestore.instance.collection('transaction').doc(order.id).update({'status': 'cancel'});
        transactionStatus = 'cancel';
      }

      if (statusType == "transaction" && filterStatuses.contains(transactionStatus)) {
        orderWidgets.add(OrderItem(order: order, filteredItems: itemsSnapshot.docs));
      } else if (statusType == "product" && transactionStatus == 'on-paid') {
        // Group the items by product status
        Map<String, List<DocumentSnapshot>> groupedItems = {};
        for (var item in itemsSnapshot.docs) {
          Map<String, dynamic> itemData = item.data() as Map<String, dynamic>;
          List<dynamic> products = itemData['products'] ?? [];

          for (var product in products) {
            String productStatus = product['status'] ?? 'Status Tidak Diketahui';

            if (productFilterStatuses != null && productFilterStatuses.contains(productStatus)) {
              if (!groupedItems.containsKey(productStatus)) {
                groupedItems[productStatus] = [];
              }
              groupedItems[productStatus]!.add(item);
            }
          }
        }

        // Add an OrderItem for each product status group
        groupedItems.forEach((status, items) {
          orderWidgets.add(
            OrderItem(
              order: order,
              filteredItems: items,
              productFilterStatus: status,
            ),
          );
        });
      }
    }

    return orderWidgets.isEmpty
        ? const Center(child: Text("Tidak ada pesanan"))
        : ListView(children: orderWidgets);
  }
}

