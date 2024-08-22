import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biumerch_mobile_app/food_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String title;
  final String description;
  final double price;
  final String image;
  final double rating;

  Product({
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    required this.rating,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is String) ? double.tryParse(data['price']) ?? 0.0 : data['price'].toDouble(),
      image: (data['imageUrls'] as List<dynamic>).isNotEmpty ? data['imageUrls'][0] : '',
      rating: (data['rating'] is String) ? double.tryParse(data['rating']) ?? 0.0 : data['rating'].toDouble(),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailPage(
              image: NetworkImage(product.image),
              title: product.title,
              price: product.price,
              rating: product.rating,
              description: product.description,
            ),
          ),
        );
      },
      child: Container(
        width: 220, // Slightly wider card
        margin: EdgeInsets.all(7.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 3,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Inner card for the image with reduced height
            Card(
              margin: EdgeInsets.all(8.0), // Remove default margin
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Inner card radius
              ),
              elevation: 5, // Elevation for the inner card
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0), // Image radius matches card radius
                child: Image.network(
                  product.image,
                  height: 160, // Reduced height for a wider card
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold, // Make the title bold
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0), // Reduce space between text widgets
                  Text(
                    formatter.format(product.price),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold, // Make the price bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.0), // Reduce space between text and rating
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF319F43), // Change background color of rating edge to #319F43
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellow[700],
                          size: 16.0,
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          product.rating.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
