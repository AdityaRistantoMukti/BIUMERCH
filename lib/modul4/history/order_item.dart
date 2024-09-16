 import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'status_helper.dart';
  import 'dart:async';
  import '../page_payment/payment_page_history.dart';
  import '../page_payment/ulasan.dart';
  import '../detail/detail_page.dart'; // Import the new detail page

  class OrderItem extends StatefulWidget {
    final DocumentSnapshot order;
    final List<DocumentSnapshot> filteredItems;
    final String? productFilterStatus;

    const OrderItem({required this.order, required this.filteredItems, this.productFilterStatus});

    @override
    _OrderItemState createState() => _OrderItemState();
  }

  class _OrderItemState extends State<OrderItem> {
    Timer? _timer;
    DateTime startTime = DateTime.now();
    String? storeName;
    bool isStoreLoaded = false;
    

    @override
    void initState() {
      super.initState();
      _loadStartTime();
      _loadStoreName();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
            _checkAndCancelExpiredTransaction(); // Cek dan batalkan jika waktu pembayaran telah berakhir

      });
    }

    @override
    void dispose() {
      _timer?.cancel();
      super.dispose();
    }
Future<void> _checkAndCancelExpiredTransaction() async {
  DateTime now = DateTime.now();

  // Ambil data transaksi dari Firestore
  final Map<String, dynamic>? data = widget.order.data() as Map<String, dynamic>?;

  if (data == null) return;

  // Ambil status transaksi
  String transactionStatus = data['status'] ?? 'unknown';

  // Cek apakah statusnya "pending"
  if (transactionStatus == 'pending') {
    // Ambil timestamp waktu kedaluwarsa (expiryTime) dari transaksi
    Timestamp? expirationTime = data['expiryTime'] as Timestamp?;

    if (expirationTime != null) {
      DateTime expiryDateTime = expirationTime.toDate();

      // Jika waktu sekarang melebihi waktu kedaluwarsa, ubah status menjadi 'cancel'
      if (now.isAfter(expiryDateTime)) {
        String transactionId = widget.order.id;

        try {
          await FirebaseFirestore.instance
              .collection('transaction')
              .doc(transactionId)
              .update({'status': 'cancel'});

          setState(() {
            // Perbarui status di UI setelah dibatalkan
            data['status'] = 'cancel';
          });

          print('Transaksi $transactionId telah dibatalkan karena waktu pembayaran habis.');
        } catch (e) {
          print('Gagal membatalkan transaksi $transactionId: $e');
        }
      }
    }
  }
}


    Future<void> _loadStoreName() async {
      if (!isStoreLoaded) {
        final itemDoc = widget.filteredItems.isNotEmpty ? widget.filteredItems[0] : null;
        if (itemDoc != null) {
          String storeId = itemDoc.id;
          DocumentSnapshot storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
          if (storeSnapshot.exists) {
            final storeData = storeSnapshot.data() as Map<String, dynamic>?;
            setState(() {
              storeName = storeData?['storeName'] ?? 'Unknown Store';
              isStoreLoaded = true;
            });
          } else {
            setState(() {
              storeName = 'Toko Tidak Ditemukan';
              isStoreLoaded = true;
            });
          }
        }
      }
    }
  Future<void> _loadStartTime() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedStartTime = prefs.getString('startTime_${widget.order.id}');

      if (savedStartTime != null) {
        setState(() {
          startTime = DateTime.parse(savedStartTime);
        });
      } else {
        await prefs.setString('startTime_${widget.order.id}', startTime.toIso8601String());
      }
    }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = widget.order.data() as Map<String, dynamic>?;

    if (data == null) {
      return Center(child: Text('Tidak ada data yang tersedia'));
    }

    String transactionStatus = data['status'] ?? 'Status Tidak Diketahui';
    String transactionId = widget.order.id;
    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    Timestamp? expirationTime = data['expiryTime'] as Timestamp?;
    double totalPrice = data['totalPriceWithTax']?.toDouble() ?? 0.0;

    if (timestamp == null || expirationTime == null) {
      return Center(child: Text('Data waktu tidak tersedia'));
    }

    DateTime startTime = timestamp.toDate();
    DateTime endTime = expirationTime.toDate();

    // Filter products with and without review
    List<DocumentSnapshot> itemsWithReview = widget.filteredItems.where((itemDoc) {
      final itemData = itemDoc.data() as Map<String, dynamic>;
      return itemData['review'] == true;
    }).toList();

    List<DocumentSnapshot> itemsWithoutReview = widget.filteredItems.where((itemDoc) {
      final itemData = itemDoc.data() as Map<String, dynamic>;
      return itemData['review'] != true;
    }).toList();

    return Column(
      children: [
        if (itemsWithReview.isNotEmpty) ...[
          _buildCard(context, data, transactionStatus, transactionId, startTime, endTime, itemsWithReview),
        ],
        if (itemsWithoutReview.isNotEmpty) ...[
          _buildCard(context, data, transactionStatus, transactionId, startTime, endTime, itemsWithoutReview),
        ],
      ],
    );
  }


  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> data,
    String transactionStatus,
    String transactionId,
    DateTime startTime,
    DateTime endTime,
    List<DocumentSnapshot> items,
  ) {
    return InkWell(
  onTap: () {
    // Ambil semua produk dari semua item yang difilter di card
    List<Map<String, dynamic>> allProducts = widget.filteredItems.expand((itemDoc) {
      final itemData = itemDoc.data() as Map<String, dynamic>;
      return (itemData['products'] as List<dynamic>? ?? []).map((product) {
        return {
          'productName': product['productName'],
          'quantity': product['quantity'],
          'productPrice': product['productPrice'],
          'productImage': product['productImage'],
          'status': product['status'],
          'review': product['review'] ?? false, // Field review (jika ada)
        };
      }).toList();
    }).toList();

    // Hitung subtotal
    double subtotal = allProducts.fold(0.0, (sum, product) {
      return sum + (product['productPrice'] * product['quantity']);
    });

    // Hitung pajak (1.3% dari subtotal)
    double tax = subtotal * 0.013;

    // Ambil total price yang sudah termasuk pajak
    double totalPriceWithTax = widget.order['totalPriceWithTax']?.toDouble() ?? 0.0;

    // Navigasi ke halaman OrderDetailPage dengan produk yang difilter, subtotal, pajak, dan total
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(
          orderNumber: widget.order.id,
          orderDate: DateFormat('dd MMMM yyyy, HH:mm').format(startTime),
          products: allProducts, // Kirim produk yang ditampilkan di card
          paymentMethod: 'QRIS', // Ubah ini sesuai kebutuhan
          totalPrice: totalPriceWithTax,
          transactionStatus: widget.order['status'],
          expiryTime: endTime,
          subtotal: subtotal,    // Kirim subtotal
          tax: tax,              // Kirim pajak
          total: totalPriceWithTax, // Kirim total yang sudah termasuk pajak
        ),
      ),
    );
  },

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, transactionStatus, transactionId, startTime, endTime),
              const Divider(),
              Text(
                'Toko: ${storeName ?? 'Loading...'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const Divider(),
              ...items.expand((itemDoc) {
                final itemData = itemDoc.data() as Map<String, dynamic>;
                final products = itemData['products'] as List<dynamic>? ?? [];
                return products.map((product) => _buildProductItem(product, transactionStatus));
              }).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(data['totalPriceWithTax'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  _buildActionButtons(context, transactionStatus, transactionId, items.any((itemDoc) {
                    final itemData = itemDoc.data() as Map<String, dynamic>;
                    return itemData['review'] == true;
                  })),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNewOrderFormat(BuildContext context, Map<String, dynamic> data, String transactionStatus, String transactionId, DateTime startTime, DateTime endTime, bool hasReview) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, transactionStatus, transactionId, startTime, endTime),
              const Divider(),
              Text(
                'Toko: ${storeName ?? 'Loading...'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const Divider(),
              ...widget.filteredItems.expand((itemDoc) {
                final itemData = itemDoc.data() as Map<String, dynamic>;
                final products = itemData['products'] as List<dynamic>? ?? [];
                return products.map((product) => _buildProductItem(product, transactionStatus));
              }).toList(),
              const Divider(),
                Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(data['totalPrice'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              _buildActionButtons(context, transactionStatus, transactionId, hasReview),
                ],
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildHeader(BuildContext context, String transactionStatus, String transactionId, DateTime startTime, DateTime expiryTime) {
    // Calculate the time difference between now and the expiryTime
    DateTime now = DateTime.now();
    Duration timeRemaining = expiryTime.difference(now);

    // Hide countdown for 'on-paid' status
    if (transactionStatus == 'on-paid') {
      return SizedBox.shrink(); // Hide countdown for 'on-paid' status
    }

    // Hide countdown and payment time for 'cancel' status, only show status text
    if (transactionStatus == 'cancel') {
      return Align(
        alignment: Alignment.centerRight, // Align to the right
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: StatusHelper.getStatusColor(transactionStatus),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            StatusHelper.getStatusText(transactionStatus),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: StatusHelper.getStatusTextColor(transactionStatus),
            ),
          ),
        ),
      );
    }

    // For statuses other than 'on-paid' and 'cancel', show the countdown
    String timeRemainingText;
    if (timeRemaining.isNegative) {
      return SizedBox.shrink(); // Hide if the time has already expired
    } else {
      // Format remaining time into hours, minutes, and seconds (HH:mm:ss)
      String hoursRemaining = timeRemaining.inHours.toString().padLeft(2, '0');
      String minutesRemaining = (timeRemaining.inMinutes % 60).toString().padLeft(2, '0');
      String secondsRemaining = (timeRemaining.inSeconds % 60).toString().padLeft(2, '0');
      timeRemainingText = '$hoursRemaining:$minutesRemaining:$secondsRemaining';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Align the content to the right
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time, // Clock icon
              color: Colors.red, // Set the icon color to red
              size: 16,
            ),
            SizedBox(width: 4), // Add some space between the icon and the text
            Text(
              timeRemainingText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red, // Set the text color to red
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        SizedBox(width: 8), // Add some space between the countdown and the status text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: StatusHelper.getStatusColor(transactionStatus),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            StatusHelper.getStatusText(transactionStatus),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: StatusHelper.getStatusTextColor(transactionStatus),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> productData, String transactionStatus) {
    String productName = productData['productName'] ?? 'Unknown Product';
    String productImage = productData['productImage'] ?? 'https://via.placeholder.com/60';
    int quantity = productData['quantity'] ?? 1;
    int productPrice = productData['productPrice'] ?? 0;
    String productStatus = productData['status'] ?? 'Status Tidak Diketahui';
    String? timeEstimate = productData['timeEstimate'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(productPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$quantity pcs',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                if (timeEstimate != null)
                  Text(
                    'Estimasi: ${_calculateDeliveryEstimate(timeEstimate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                if (transactionStatus != 'pending' && transactionStatus != 'cancel')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusHelper.getStatusColor(productStatus),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      StatusHelper.getStatusText(productStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: StatusHelper.getStatusTextColor(productStatus),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    String _calculateDeliveryEstimate(String timeEstimate) {
      DateTime now = DateTime.now();
      
      // Check if the timeEstimate is in the date format (dd-MM-yyyy)
      try {
        DateTime estimateDate = DateFormat('dd-MM-yyyy').parse(timeEstimate);
        int differenceInDays = estimateDate.difference(now).inDays;

        if (differenceInDays <= 7) {
          return '$differenceInDays hari';
        } else {
          return DateFormat('EEEE, dd-MM-yyyy').format(estimateDate);
        }
      } catch (e) {
        // If it's not a date, assume it's a time-based string like "25-35 minutes"
        List<String> timeRange = timeEstimate.split('-');
        int minTime = int.parse(timeRange[0].replaceAll(RegExp(r'\D'), ''));
        int maxTime = int.parse(timeRange[1].replaceAll(RegExp(r'\D'), ''));

        int minutesElapsed = now.difference(startTime).inMinutes;

        int remainingMin = minTime - minutesElapsed;
        int remainingMax = maxTime - minutesElapsed;

        // Ensure the remaining time is not negative
        if (remainingMin < 0) remainingMin = 0;
        if (remainingMax < 0) remainingMax = 0;

        return '$remainingMin-$remainingMax menit';
      }
    }

  Widget _buildActionButtons(BuildContext context, String transactionStatus, String transactionId, bool hasReview) {
    List<Widget> buttons = [];

    // Add "Bayar" button for pending transactions
    if (transactionStatus == "pending") {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentHistoryPage(transactionId: transactionId),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Check if all products are marked as "completed"
    bool allProductsCompleted = widget.filteredItems.every((item) {
      final itemData = item.data() as Map<String, dynamic>;
      final products = itemData['products'] as List<dynamic>? ?? [];
      return products.every((product) => product['status'] == 'completed');
    });

    // If there are products in "completed-delivery" status, allow confirmation
    if (!allProductsCompleted && widget.productFilterStatus == 'completed-delivery') {
      List<Map<String, dynamic>> completedDeliveryProducts = [];
      for (var item in widget.filteredItems) {
        final itemData = item.data() as Map<String, dynamic>;
        final products = itemData['products'] as List<dynamic>? ?? [];
        for (var product in products) {
          if (product['status'] == 'completed-delivery') {
            completedDeliveryProducts.add(product);
          }
        }
      }

      if (completedDeliveryProducts.isNotEmpty) {
        buttons.add(
          ElevatedButton(
            onPressed: () {
              _showConfirmationDialog(context, transactionId, completedDeliveryProducts);
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }

    // Add "Tulis Ulasan" button if all products are completed and review has not been given
    if (allProductsCompleted) {
        // Prepare the stores data to pass to the ReviewPage
        List<Map<String, dynamic>> stores = [];
        bool hasUnreviewedProduct = false;
        for (var item in widget.filteredItems) {
          String storeId = item.id;
          Map<String, dynamic> itemData = item.data() as Map<String, dynamic>;
          List<dynamic> products = itemData['products'] ?? [];
          
          List<Map<String, dynamic>> unreviewedProducts = [];
          for (var product in products) {
            if (product['status'] == 'completed' && product['review'] != true) {
              unreviewedProducts.add(product);
              hasUnreviewedProduct = true;
            }
          }
          
          if (unreviewedProducts.isNotEmpty) {
            stores.add({
              'storeId': storeId,
              'items': unreviewedProducts,
            });
          }
        }

        // Only show the "Tulis Ulasan" button if there are unreviewed products
        if (hasUnreviewedProduct) {
          buttons.add(
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewPage(
                      transactionId: transactionId,
                      stores: stores, // Pass only unreviewed store data to ReviewPage
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
      }

      // Return the row of buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons,
      );
    }
    Future<void> _showConfirmationDialog(BuildContext context, String transactionId, List<Map<String, dynamic>> completedDeliveryProducts) async {
    double totalPrice = completedDeliveryProducts.fold(0, (sum, product) => sum + (product['productPrice'] ?? 0) * (product['quantity'] ?? 1));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Sesuaikan dengan color palette
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Membuat border dialog lebih halus
          ),
          title: Row(
            children: [
              Icon(
                Icons.shopping_cart, // Ikon untuk memperindah tampilan
                color: Colors.green, // Sesuaikan dengan color palette
              ),
              SizedBox(width: 8),
              Text(
                "Konfirmasi Pesanan",
                style: TextStyle(
                                  fontSize: 20,
                  fontFamily: 'Nunito', // Gunakan font yang konsisten dengan aplikasi
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Warna teks utama
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total yang harus dibayar:",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  color: Colors.black87, // Warna teks utama
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalPrice)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green, // Warna hijau untuk jumlah total
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Konfirmasi pesanan dan serahkan jumlah tersebut kepada toko.",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  color: Colors.grey[600], // Warna teks deskripsi
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black), // Border hitam
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Batal",
                style: TextStyle(
                  color: Colors.black, // Warna teks hitam
                  fontSize: 14,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateProductStatusesAndStoreBalances(transactionId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Warna hijau untuk tombol Konfirmasi
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Membuat tombol lebih halus
                ),
              ),
              child: Text(
                "Konfirmasi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updateProductStatusesAndStoreBalances(String transactionId) async {
    try {
      print("Starting update process for transaction: $transactionId");

      DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
          .collection('transaction')
          .doc(transactionId)
          .get();

      final transactionData = transactionDoc.data() as Map<String, dynamic>?;

      if (transactionData != null) {
        List<dynamic> stores = transactionData['stores'] ?? [];
        print("Found ${stores.length} stores in the transaction");

        for (var store in stores) {
          String storeId = store['storeId'];
          print("Processing store: $storeId");

          DocumentSnapshot itemsDoc = await FirebaseFirestore.instance
              .collection('transaction')
              .doc(transactionId)
              .collection('items')
              .doc(storeId)
              .get();

          if (itemsDoc.exists) {
            Map<String, dynamic> itemsData = itemsDoc.data() as Map<String, dynamic>;
            List<dynamic> products = itemsData['products'] ?? [];
            double storeTotalPrice = 0;

            for (int i = 0; i < products.length; i++) {
              var product = products[i];
              if (product['status'] == 'completed-delivery') {
                product['status'] = 'completed';
                double productPrice = (product['productPrice'] ?? 0).toDouble();
                int quantity = (product['quantity'] ?? 1).toInt();
                storeTotalPrice += productPrice * quantity;
                print("Updated product status to completed: ${product['productName']}");
              }
            }

            // Update products in the items subcollection
            await FirebaseFirestore.instance
                .collection('transaction')
                .doc(transactionId)
                .collection('items')
                .doc(storeId)
                .update({
                  'products': products,
                });
            print("Updated products in items subcollection for store $storeId");

            if (storeTotalPrice > 0) {
              print("Updating balance for store $storeId: $storeTotalPrice");
              await _updateStoreBalance(storeId, storeTotalPrice.round());
            }
          } else {
            print("Items document not found for store $storeId");
          }
        }
      }
    } catch (e) {
      print("Error updating product statuses and store balances: $e");
    }
  }


    Future<bool> _checkAllStoresCompleted(String transactionId) async {
      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
          .collection('transaction')
          .doc(transactionId)
          .collection('items')
          .get();

      for (var doc in itemsSnapshot.docs) {
        List<dynamic> products = (doc.data() as Map<String, dynamic>)['products'] ?? [];
        for (var product in products) {
          if (product['status'] != 'completed') {
            return false;
          }
        }
      }
      return true;
    }

  Future<void> _updateStoreBalance(String storeId, int amount) async {
      try {
        DocumentReference storeRef = FirebaseFirestore.instance.collection('stores').doc(storeId);
        
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot storeSnapshot = await transaction.get(storeRef);
          
          if (storeSnapshot.exists) {
            Map<String, dynamic> storeData = storeSnapshot.data() as Map<String, dynamic>;
            int currentBalance = (storeData['balance'] ?? 0).toInt();
            int newBalance = currentBalance + amount;

            transaction.update(storeRef, {'balance': newBalance});
          } else {
            transaction.set(storeRef, {'balance': amount});
          }
        });
      } catch (e) {
        print("Error updating store balance: $e");
      }
    }


  }