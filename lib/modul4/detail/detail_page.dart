import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../page_payment/payment_page_history.dart';
import '../page_payment/ulasan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

  class OrderDetailPage extends StatefulWidget {
    final String orderNumber;
    final String orderDate;
    final List<Map<String, dynamic>> products; // Ubah ini menjadi list produk
    final String paymentMethod;
    final double totalPrice;
    final String transactionStatus;
    final double subtotal;
    final double tax;
    final double total;
    final DateTime expiryTime;

    OrderDetailPage({
      required this.orderNumber,
      required this.orderDate,
      required this.products, // Terima list produk
      required this.paymentMethod,
      required this.totalPrice,
       required this.subtotal,    // Tambahkan ini
    required this.tax,         // Tambahkan ini
    required this.total,       // Tambahkan ini
      required this.transactionStatus,
      required this.expiryTime,
      
    });

    @override
    _OrderDetailPageState createState() => _OrderDetailPageState();
  }


 class _OrderDetailPageState extends State<OrderDetailPage> {
  Timer? _timer;
  Duration remainingTime = Duration(); // Always initialized to avoid null issues
  String productStatus = '';
  bool hasReview = false;
  double refundAmount = 0.0;  // <-- Declare refundAmount here
List<Map<String, dynamic>> fetchedProducts = [];

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateRemainingTime();
      });
    });
    _fetchProductStatus();
    fetchOrderData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
Future<void> fetchOrderData() async {
  try {
    // Fetch the main transaction document
    DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
        .collection('transaction')
        .doc(widget.orderNumber)
        .get();

    if (transactionDoc.exists) {
      Map<String, dynamic>? transactionData = transactionDoc.data() as Map<String, dynamic>?;

      if (transactionData != null) {
        List<dynamic> stores = transactionData['stores'] ?? [];
        List<Map<String, dynamic>> tempProducts = []; // Temporarily store products

        for (var store in stores) {
          String storeId = store['storeId'] ?? '';

          // Fetch items document for the storeId
          DocumentSnapshot itemsDoc = await FirebaseFirestore.instance
              .collection('transaction')
              .doc(widget.orderNumber)
              .collection('items')
              .doc(storeId)
              .get();

          if (itemsDoc.exists) {
            Map<String, dynamic>? itemsData = itemsDoc.data() as Map<String, dynamic>?;

            if (itemsData != null) {
              List<dynamic> products = itemsData['products'] ?? [];

              for (var product in products) {
                String? proofPhotoUrl = product['proofPhotoUrl'];
                String productName = product['productName'] ?? 'Unknown Product';
                String status = product['status'] ?? 'Unknown Status';

                // Add each product to the temporary list
                tempProducts.add({
                  ...product, // Add existing product fields
                  'proofPhotoUrl': proofPhotoUrl, // Ensure proofPhotoUrl is added
                });

                // Log the correct proofPhotoUrl
                if (proofPhotoUrl != null && proofPhotoUrl.isNotEmpty) {
                  print("Product Name: $productName");
                  print("Product Status: $status");
                  print("Proof Photo URL: $proofPhotoUrl");
                } else {
                  print("Proof Photo URL is missing for product: $productName");
                }
              }
            }
          }
        }

        // Update state with fetched products
        setState(() {
          fetchedProducts = tempProducts;
        });
      }
    }
  } catch (e) {
    print("Error fetching Firestore data: $e");
  }
}

  void _calculateRemainingTime() {
    final now = DateTime.now();
    // Safeguard: Ensure expiryTime exists and is a valid DateTime
    if (widget.expiryTime != null) {
      remainingTime = widget.expiryTime.difference(now);
      if (remainingTime.isNegative) {
        _timer?.cancel();
      }
    } else {
      remainingTime = Duration.zero; // Set to zero if expiryTime is invalid
    }
  }

  Widget _buildCountdown() {
    // No need to check for null because `remainingTime` is initialized in initState
    if (remainingTime.isNegative) {
      return Text(
        'Waktu Pembayaran Habis',
        style: TextStyle(fontSize: 14, color: Colors.red, fontFamily: 'Nunito'),
      );
    }

    final String countdownText =
        '${remainingTime.inHours.toString().padLeft(2, '0')}:${(remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';

    return Text(
      'Waktu Habis: $countdownText',
      style: TextStyle(fontSize: 14, color: Colors.red, fontFamily: 'Nunito'),
    );
  }

 Future<void> _fetchProductStatus() async {
  try {
    if (widget.products.isNotEmpty) {
      var product = widget.products.first;

      bool hasCompletedDelivery = false;
      bool allCompleted = true;
      bool hasWaitingConfirmation = false;

      // Check product status from Firestore or widget.products
      if (product['status'] == 'completed-delivery') {
        hasCompletedDelivery = true;
      }
      if (product['status'] == 'waiting-store-confirmation') {
        hasWaitingConfirmation = true;
      }
      if (product['status'] != 'completed') {
        allCompleted = false;
      }

      setState(() {
        if (hasCompletedDelivery) {
          productStatus = 'completed-delivery';
        } else if (hasWaitingConfirmation) {
          productStatus = 'waiting-store-confirmation';
        } else if (allCompleted) {
          productStatus = 'completed';
        } else {
          productStatus = 'processing';
        }
        hasReview = product['review'] == true;

        // Debug print to verify the status
        print('Product Status: $productStatus');
      });
    }
  } catch (e) {
    print("Error fetching product status: $e");
  }
}

@override
Widget build(BuildContext context) {
  String formattedTotalPrice = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(widget.totalPrice);

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Detail Pesanan',
        style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderStatus(),
                SizedBox(height: 20),
                _buildProductDetails(), // Tampilkan semua produk
                SizedBox(height: 16),
                _buildPaymentSummary(formattedTotalPrice),
              ],
            ),
          ),
        ),
        _buildConditionalButtons(context),
      ],
    ),
  );
}

  Widget _buildOrderStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getStatusText(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Nunito',
          ),
        ),
        if (widget.transactionStatus == 'pending') _buildCountdown(),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'No. Pesanan',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF0B4D3B), fontFamily: 'Nunito'),
            ),
            Text(
              widget.orderNumber,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B4D3B),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tanggal Pesanan',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF0B4D3B), fontFamily: 'Nunito'),
            ),
            Text(
              widget.orderDate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B4D3B),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText() {
  if (widget.transactionStatus == 'canceled-by-user') {
    return 'Pesanan Dibatalkan'; // Update for canceled status
  } else if (widget.transactionStatus == 'cancel') {
    return 'Pembayaran Gagal';
  } else if (widget.transactionStatus == 'pending') {
    return 'Belum Bayar';
  } else if (productStatus == 'completed') {
    return 'Pesanan Selesai';
  } else {
    return 'Pesanan Diproses';
  }
}

Widget _buildProductDetails() {
  // Use fetchedProducts for rendering the product details
  if (fetchedProducts.isEmpty) {
    return Text('Loading products...'); // Show a loading message if products aren't fetched yet
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Detail Produk',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Nunito',
        ),
      ),
      SizedBox(height: 8),
      Column(
        children: fetchedProducts.map((product) {
          String formattedPrice = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(product['productPrice']);
          String? proofPhotoUrl = product['proofPhotoUrl'];

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['productImage'] ?? 'https://via.placeholder.com/60',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show "Lihat Bukti Pengiriman" if the product is completed or completed-delivery and proofPhotoUrl exists
                        if ((product['status'] == 'completed-delivery' || product['status'] == 'completed') && proofPhotoUrl != null) ...[
                          GestureDetector(
                            onTap: () {
                              _showProofPhotoDialog(context, proofPhotoUrl);
                            },
                            child: Text(
                              'Lihat Bukti Pengiriman',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue, // Blue text for link-like appearance
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        // Product name
                        Text(
                          product['productName'] ?? 'Unknown Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 4),
                        // Product quantity
                        Text(
                          '${product['quantity']} pcs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 4),
                        // Product price
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 4),
                        // Product status
                        if (product['status'] == 'canceled-by-user') ...[
                          Text(
                            'Pesanan Dibatalkan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ] else if (product['status'] == 'completed-delivery') ...[
                          Text(
                            'Pesanan Selesai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ] else if (product['status'] == 'completed') ...[
                          Text(
                            'Pesanan Selesai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Pesanan Diproses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}


void _showProofPhotoDialog(BuildContext context, String proofPhotoUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Bukti Pengiriman",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            // Display the proof photo
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  proofPhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'Gagal memuat gambar',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildPaymentSummary(String formattedTotalPrice) {
  // Format subtotal dan pajak
  String formattedSubtotal = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(widget.subtotal);

  String formattedTax = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(widget.tax);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Metode Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B4D3B), fontFamily: 'Nunito'),
          ),
          Text(
            widget.paymentMethod,
            style: TextStyle(fontSize: 14, color: Color(0xFF0B4D3B), fontFamily: 'Nunito'),
          ),
        ],
      ),
      SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Subtotal:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            formattedSubtotal,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pajak (1.3%):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            formattedTax,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Harga:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            formattedTotalPrice, // Total yang sudah diformat sebelumnya
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B4D3B),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildConditionalButtons(BuildContext context) {
  // Adjust buttons based on product status and transaction status
  if (productStatus == 'completed-delivery') {
    return _buildConfirmOrderButton(context);
  } else if (productStatus == 'completed' && !hasReview) {
    return _buildReviewButton(context);
  } else if (productStatus == 'waiting-store-confirmation' && widget.transactionStatus == 'on-paid') {
    // Add transaction status check for 'on-paid'
    return _buildCancelButtonWithRefund(context);
  } else if (widget.transactionStatus == 'pending') {
    return _buildPayButton(context);
  } else {
    return SizedBox.shrink();
  }
}


Widget _buildConfirmOrderButton(BuildContext context) {
  // Hanya produk dengan status "completed-delivery" yang diproses
  List<Map<String, dynamic>> completedDeliveryProducts = widget.products
      .where((product) => product['status'] == 'completed-delivery')
      .toList();

  if (completedDeliveryProducts.isEmpty) {
    return SizedBox.shrink(); // Tidak ada produk dengan status completed-delivery
  }

  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          _showConfirmationDialog(context, completedDeliveryProducts); // Tampilkan dialog konfirmasi
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Konfirmasi Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Future<void> _confirmOrder(BuildContext context, List<Map<String, dynamic>> completedDeliveryProducts) async {
  try {
    // Update status produk di Firestore
    DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
        .collection('transaction')
        .doc(widget.orderNumber)
        .get();

    if (transactionDoc.exists) {
      Map<String, dynamic> transactionData = transactionDoc.data() as Map<String, dynamic>;
      List<dynamic> stores = transactionData['stores'] ?? [];

      for (var store in stores) {
        String storeId = store['storeId'];
        DocumentSnapshot itemsDoc = await FirebaseFirestore.instance
            .collection('transaction')
            .doc(widget.orderNumber)
            .collection('items')
            .doc(storeId)
            .get();

        if (itemsDoc.exists) {
          Map<String, dynamic> itemsData = itemsDoc.data() as Map<String, dynamic>;
          List<dynamic> products = itemsData['products'] ?? [];

        for (var product in products) {
    // Log product details for debugging
    print('Product Data: ${product.toString()}');

    if (product['status'] == 'waiting-store-confirmation') {
        // Safely retrieve TotalPriceProduct and quantity with logging
        double totalPriceProduct = (product['TotalPriceProduct'] ?? 0).toDouble();
        double quantity = (product['quantity'] ?? 1).toDouble();

        // Log the values retrieved for each product
        print('Retrieved TotalPriceProduct: $totalPriceProduct, Quantity: $quantity');
        
        // If the values are valid, perform refund calculation
        if (totalPriceProduct > 0 && quantity > 0) {
            refundAmount += totalPriceProduct * quantity;
        } else {
            print('Invalid TotalPriceProduct or Quantity: Skipping this product');
        }

        // Update the product status
        product['status'] = 'canceled-by-user';
    } else {
        print('Product status not matching: ${product['status']}');
    }
}


          // Update status produk di Firestore
          await FirebaseFirestore.instance
              .collection('transaction')
              .doc(widget.orderNumber)
              .collection('items')
              .doc(storeId)
              .update({
            'products': products,
          });

          setState(() {
            productStatus = 'completed'; // Ubah status lokal menjadi "completed"
          });
        }
      }
    }
  } catch (e) {
    print("Error confirming order: $e");
  }
}



 Widget _buildReviewButton(BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          await _navigateToReviewPage(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Tulis Ulasan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
  Future<void> _navigateToReviewPage(BuildContext context) async {
    // Simulate getting data from Firestore and filtering products that need a review
    List<Map<String, dynamic>> stores = [];
    bool hasUnreviewedProduct = false;

    try {
      // Fetch the transaction and store data from Firestore
      DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
          .collection('transaction')
          .doc(widget.orderNumber)
          .get();

      if (transactionDoc.exists) {
        Map<String, dynamic> transactionData = transactionDoc.data() as Map<String, dynamic>;
        List<dynamic> storesData = transactionData['stores'] ?? [];

        for (var store in storesData) {
          String storeId = store['storeId'];
          DocumentSnapshot itemsDoc = await FirebaseFirestore.instance
              .collection('transaction')
              .doc(widget.orderNumber)
              .collection('items')
              .doc(storeId)
              .get();

          if (itemsDoc.exists) {
            Map<String, dynamic> itemsData = itemsDoc.data() as Map<String, dynamic>;
            List<dynamic> products = itemsData['products'] ?? [];
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
        }

        if (hasUnreviewedProduct) {
          // Push data to ReviewPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(
                transactionId: widget.orderNumber,
                stores: stores, // Pass filtered stores with unreviewed products
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }


  Widget _buildPayButton(BuildContext context) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentHistoryPage(transactionId: widget.orderNumber)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Bayar',
              style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Nunito', fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }


   Widget _buildCancelButtonWithRefund(BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          _showCancelAndRefundDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Batalkan Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    ),
  );
}
void _showCancelAndRefundDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Konfirmasi Pembatalan',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Jumlah akan dikembalikan ke saldo.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog without canceling
            },
            child: Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _cancelOrderAndRefund(context);
              Navigator.of(context).pop(); // Close dialog
              Navigator.pop(context); // Close order detail page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
    
Future<void> _cancelOrderAndRefund(BuildContext context) async {
  try {
    // Get the current logged-in user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user is logged in.");
      return;
    }

    // Use the current user's uid to fetch their user document
    String uid = currentUser.uid;

    // Fetch the current user document
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // Use the current logged-in user's UID
        .get();

    // Initialize currentBalance, assuming a default value of 0 if the balance field doesn't exist
    double currentBalance = 0.0;

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('balance')) {
        currentBalance = (userData['balance'] ?? 0.0).toDouble(); // Safely cast balance to double
      }
    }

    // Reset refundAmount to 0 before calculating
    refundAmount = 0.0;

    // Fetch the transaction document
    DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
        .collection('transaction')
        .doc(widget.orderNumber)
        .get();

    if (transactionDoc.exists) {
      List<dynamic> stores = transactionDoc['stores'] ?? [];

      for (var store in stores) {
        String storeId = store['storeId'];

        DocumentSnapshot itemsDoc = await FirebaseFirestore.instance
            .collection('transaction')
            .doc(widget.orderNumber)
            .collection('items')
            .doc(storeId)
            .get();

        if (itemsDoc.exists) {
          List<dynamic> products = itemsDoc['products'] ?? [];

          for (var product in products) {
            if (product['status'] == 'waiting-store-confirmation') {
              // Restore stock for this product in the Firestore 'products' collection
              await _restoreProductStock(product);

              // Calculate refund amount
              double totalPriceProduct = (product['totalPriceProduct'] ?? 0).toDouble();
              double quantity = (product['quantity'] ?? 1).toDouble();

              refundAmount += totalPriceProduct * quantity;
              product['status'] = 'canceled-by-user'; // Update product status
            }
          }

          // Update the products in Firestore after canceling them
          await FirebaseFirestore.instance
              .collection('transaction')
              .doc(widget.orderNumber)
              .collection('items')
              .doc(storeId)
              .update({'products': products});
        }
      }
    }


    // Add refund amount (totalPriceProduct) to user's balance
    double updatedBalance = currentBalance + refundAmount;


    // Update or create the 'balance' field for the user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // Use the current logged-in user's UID
        .set({'balance': updatedBalance}, SetOptions(merge: true)); // Merge with existing fields

    // Update the transaction status to canceled
    await FirebaseFirestore.instance
        .collection('transaction')
        .doc(widget.orderNumber)
        .update({'status': 'canceled-by-user'});

    // Ensure the widget is mounted before calling setState
    if (!mounted) return;
    setState(() {
      productStatus = 'canceled-by-user'; // Update local state
    });
  } catch (e) {
    print("Error canceling order and refunding: $e");
  }
}
Future<void> _restoreProductStock(Map<String, dynamic> product) async {
  try {
    String productId = product['productId'];
    int quantity = (product['quantity'] ?? 0).toInt();

    // Get a reference to the product document in Firestore
    DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(productId);

    // Run a transaction to restore the stock safely
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot productSnapshot = await transaction.get(productRef);

      if (productSnapshot.exists) {
        int currentStock = productSnapshot['stock'] ?? 0;
        int newStock = currentStock + quantity;

        // Update the stock in the product document
        transaction.update(productRef, {'stock': newStock});

        print('Stock restored for product $productId: New stock is $newStock');
      } else {
        print('Product $productId does not exist.');
      }
    });
  } catch (e) {
    print("Error restoring product stock: $e");
  }
}


  
void _showConfirmationDialog(BuildContext context, List<Map<String, dynamic>> completedDeliveryProducts) {
  // Hitung total harga hanya untuk produk dengan status completed-delivery
  double totalPrice = completedDeliveryProducts.fold(0, (sum, product) {
    return sum + (product['productPrice'] ?? 0) * (product['quantity'] ?? 1);
  });

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text(
              "Konfirmasi Pesanan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalPrice)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Konfirmasi pesanan untuk produk dengan status 'completed-delivery'.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.black),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Batal",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmOrder(context, completedDeliveryProducts); // Proses konfirmasi hanya untuk produk completed-delivery
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Konfirmasi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  }