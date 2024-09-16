 import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';

  class ReviewPage extends StatefulWidget {
    final String transactionId;
    final List<Map<String, dynamic>> stores;

    ReviewPage({required this.transactionId, required this.stores});

    @override
    _ReviewPageState createState() => _ReviewPageState();
  }

class _ReviewPageState extends State<ReviewPage> {
  final List<TextEditingController> _reviewControllers = [];
  final List<int> _ratings = [];

  @override
  void initState() {
    super.initState();

    // Ensure that _reviewControllers and _ratings are initialized for each product in all stores
    for (var store in widget.stores) {
      for (var item in store['items']) {
        _reviewControllers.add(TextEditingController());
        _ratings.add(0); // Default rating is 0
      }
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers when no longer needed
    for (var controller in _reviewControllers) {
      controller.dispose();
    }
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ulas Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF144817),
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.stores.length,
                itemBuilder: (context, storeIndex) {
                  final store = widget.stores[storeIndex];
                  final storeId = store['storeId'];
                  final items = store['items'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      ...items.asMap().entries.map((entry) {
                        final int itemIndex = entry.key;
                        final item = entry.value;
                        final int globalIndex = _getGlobalIndex(storeIndex, itemIndex);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductCard(
                              item['productImage'] ?? 'https://via.placeholder.com/60',
                              item['productName'] ?? 'Unknown Product',
                              item['quantity'] ?? 1,
                              item['productPrice'] ?? 0,
                            ),
                            _buildRatingBar(globalIndex),
                            SizedBox(height: 10),
                            _buildReviewInput(globalIndex),
                            SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }




Widget _buildProductCard(String productImage, String productName, int quantity, int productPrice) {
  return Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          productImage,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error);
          },
        ),
      ),
      SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: TextStyle(
              color: Color(0xFF8D8585),
              fontSize: 18,
            ),
          ),
          Text(
            '$quantity pcs',
            style: TextStyle(
              color: Color(0xFF8D8585),
            ),
          ),
          Text(
            'Rp $productPrice',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildRatingBar(int index) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (starIndex) {
      return IconButton(
        icon: Icon(
          starIndex < _ratings[index] ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 36,
        ),
        onPressed: () {
          setState(() {
            _ratings[index] = starIndex + 1;
          });
        },
      );
    }),
  );
}

Widget _buildReviewInput(int index) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Color(0xFFEEEEEE), // Light gray background color
    ),
    child: TextField(
      controller: _reviewControllers[index],
      maxLines: 8,
      decoration: InputDecoration(
        hintText: 'Tulis ulasan lengkap kamu tentang produk ini disini ya!',
        border: InputBorder.none, // Remove the underline
        contentPadding: EdgeInsets.all(10), // Add padding inside the text field
      ),
    ),
  );
}

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          try {
            // Submit review for each product
            for (int storeIndex = 0; storeIndex < widget.stores.length; storeIndex++) {
              final store = widget.stores[storeIndex];
              final storeId = store['storeId'];
              final items = store['items'];

              for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
                final globalIndex = _getGlobalIndex(storeIndex, itemIndex);
                final reviewText = _reviewControllers[globalIndex].text;
                final rating = _ratings[globalIndex];
                final productItem = items[itemIndex];
                final productId = productItem['productId'];

                if (productId != null && productId.isNotEmpty) {
                  // Add the review to the product's reviews collection
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .collection('reviews')
                      .add({
                    'userId': user.uid,
                    'productId': productId,
                    'rating': rating,
                    'review': reviewText,
                    'storeId': storeId,
                    'transactionId': widget.transactionId,
                  });

                  // Mark the specific product as reviewed in the 'items' sub-collection under the transaction
                  final productPath = 'transaction/${widget.transactionId}/items/$storeId';
                  final productDoc = FirebaseFirestore.instance.doc(productPath);

                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    DocumentSnapshot snapshot = await transaction.get(productDoc);
                    if (snapshot.exists) {
                      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
                      List<dynamic> products = data['products'] ?? [];
                      int productIndex = products.indexWhere((p) => p['productId'] == productId);
                      if (productIndex != -1) {
                        products[productIndex]['review'] = true;
                        transaction.update(productDoc, {'products': products});
                      }
                    }
                  });
                }
              }
            }

          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                    SizedBox(height: 16),
                    Text(
                      "Ulasan Dikirim",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Text(
                  "Ulasan Anda telah berhasil dikirim. Terima kasih atas feedback Anda!",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.of(context).pop(); // Go back to the previous page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } catch (e) {
          print('Error: ${e.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pengguna tidak terautentikasi')),
        );
      }
    },
    child: Text(
      'Kirim Ulasan',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF06E60E),
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}


int _getGlobalIndex(int storeIndex, int itemIndex) {
  int globalIndex = 0;
  for (int i = 0; i < storeIndex; i++) {
    globalIndex += (widget.stores[i]['items'].length as int); // Cast to int
  }
  return globalIndex + itemIndex;
}

int _getStoreIndex(int globalIndex) {
  int itemCount = 0;
  for (int i = 0; i < widget.stores.length; i++) {
    itemCount += (widget.stores[i]['items'].length as int); // Cast to int
    if (globalIndex < itemCount) {
      return i;
    }
  }
  return 0;
}

int _getPreviousItemCount(int storeIndex) {
  int count = 0;
  for (int i = 0; i < storeIndex; i++) {
    count += (widget.stores[i]['items'].length as int); // Cast to int
  }
  return count;
}

}