import 'package:biumerch_mobile_app/product.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SearchResultsPage extends StatelessWidget {
  final String query;

  SearchResultsPage({required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 25,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AbsorbPointer(  // AbsorbPointer untuk mencegah interaksi
                child: TextField(
                  enabled: false,  // Disable editing in the current page
                  controller: TextEditingController(text: query),
                  decoration: InputDecoration(
                    hintText: 'Mau cari apa?',
                    suffixIcon: Icon(Icons.search),  // Mengubah dari suffix ke prefix
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),  // Mengubah radius sesuai UI yang diinginkan
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    filled: true,
                    // fillColor: Colors.grey[200],  // Warna background yang diinginkan
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Periksa jika snapshot memiliki data yang valid
          List<Product> products = snapshot.data!.docs.map((doc) {
            try {
              return Product.fromFirestore(doc); // Tangani dan debug kesalahan di sini
            } catch (e) {
              print('Error creating Product: $e'); // Log kesalahan
              return null; // Tangani kesalahan dengan baik
            }
          }).whereType<Product>().toList(); // Hilangkan nilai null

          List<Product> searchResults = _performSubstringSearch(query, products);

          if (searchResults.isEmpty) {
            return Center(child: Text('Tidak Ditemukan'));
          }

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding to the grid
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: searchResults[index],
              );
            },
          );
        },
      ),
    );
  }

  List<Product> _performSubstringSearch(String query, List<Product> products) {
    // Convert query to lowercase for case-insensitive search
    final lowerQuery = query.toLowerCase();
    
    return products.where((product) {
      // Convert product title to lowercase and check if it contains the query
      return product.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}


