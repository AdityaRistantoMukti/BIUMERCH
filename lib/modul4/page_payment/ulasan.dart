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
    _reviewControllers.addAll(widget.stores.expand((store) => store['items']).map((_) => TextEditingController()).toList());
    _ratings.addAll(widget.stores.expand((store) => store['items']).map((_) => 0).toList());
  }

  @override
  void dispose() {
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
            color: Color(0xFF144817), // Dark green color for the title
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
        child: ListView.builder(
          itemCount: widget.stores.length,
          itemBuilder: (context, storeIndex) {
            final store = widget.stores[storeIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: store['items'].map<Widget>((item) {
                final itemIndex = store['items'].indexOf(item);
                final controllerIndex = storeIndex * store['items'].length + itemIndex;

                final productId = item['productId'];
                final productName = item['productName'] ?? 'Unknown Product';
                final quantity = item['quantity'] ?? 1;
                final productPrice = item['productPrice'] ?? 0;
                final productImage = item['productImage'] ?? 'https://via.placeholder.com/60';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductCard(productImage, productName, quantity, productPrice),
_buildRatingBar(controllerIndex.toInt()),    // Ensure controllerIndex is an int
                    SizedBox(height: 10),
_buildReviewInput(controllerIndex.toInt()),  // Ensure controllerIndex is an int
                    SizedBox(height: 20),
                  _buildSubmitButton(
  controllerIndex.toInt(),                    // Ensure controllerIndex is an int
  store['storeId'],
  productId,
  productName,
  quantity.toInt(),                           // Ensure quantity is an int
  productPrice.toInt(),                       // Ensure productPrice is an int
),
                  ],
                );
              }).toList(),
            );
          },
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
              'Rp ${productPrice}',
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

 Widget _buildSubmitButton(int index, String storeId, String productId, String productName, int quantity, int productPrice) {
  return ElevatedButton(
    onPressed: () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && productId.isNotEmpty) {
        print("User ID: ${user.uid}");
        print("Transaction ID: ${widget.transactionId}");
        print("Store ID: $storeId");
        print("Product ID: $productId");

        try {
          // Save the review to the appropriate product's reviews subcollection
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId) // Navigate to the specific product document
              .collection('reviews') // Create a reviews subcollection
              .add({
            'userId': user.uid,
            'productId': productId,
            'productName': productName,
            'quantity': quantity,
            'rating': _ratings[index],
            'review': _reviewControllers[index].text,
            'storeId': storeId,
            'transactionId': widget.transactionId,
          });

          // Construct the document path for the transaction
          final transactionPath = 'users/${user.uid}/transaksi/${widget.transactionId}';
          print('Attempting to update document at path: $transactionPath');

          // Check if the transaction document exists
          final transactionDoc = FirebaseFirestore.instance
              .doc(transactionPath);

          final transactionSnapshot = await transactionDoc.get();

          if (transactionSnapshot.exists) {
            print("Transaction document found.");
            // Update the transaction document to mark it as reviewed
            await transactionDoc.update({'review': true});

            // Show a success popup with enhanced UI
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  title: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                      ),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
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
                          backgroundColor: Colors.green, // Green button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.white, // White text color
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  actionsPadding: EdgeInsets.only(bottom: 16),
                );
              },
            );
          } else {
            print('Transaction document does not exist: $transactionPath');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi tidak ditemukan')));
          }
        } catch (e) {
          print('Error: ${e.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID produk tidak valid atau pengguna tidak terautentikasi')));
      }
    },
    child: Text(
      'Kirim',
      style: TextStyle(
        color: Colors.white, // White text color
        fontWeight: FontWeight.bold, // Bold text
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF06E60E), // Green background color
      minimumSize: Size(double.infinity, 50), // Full width button with 50 height
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
    ),
  );
}


}