import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For Rupiah currency formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanChatPenjual extends StatefulWidget {
  final String roomId;
  final String buyerUID;
  final String sellerUID;
  final String storeName;
  final String? draftProductId; // Produk dalam draft
  final String? draftProductName;
  final String? draftProductImage;
  final double? draftProductPrice;

  const HalamanChatPenjual({
    super.key,
    required this.roomId,
    required this.buyerUID,
    required this.sellerUID,
    required this.storeName,
    this.draftProductId, // Tambahkan untuk draft produk
    this.draftProductName,
    this.draftProductImage,
    this.draftProductPrice,
  });

  @override
  _HalamanChatPenjualState createState() => _HalamanChatPenjualState();
}

class _HalamanChatPenjualState extends State<HalamanChatPenjual> {
  final TextEditingController _messageController = TextEditingController();
  bool _isProductCardSent = false; // Flag untuk melacak apakah kartu produk telah dikirim

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Chat messages section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada pesan'));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    String? messageType = message.data().toString().contains('type') ? message['type'] : 'text';
                    bool isSender = message['senderUID'] == FirebaseAuth.instance.currentUser?.uid;

                    if (messageType == 'product_card') {
                      var productCard = message['message'];
                      String imageUrl = productCard['image'] ?? '';
                      String name = productCard['name'];
                      double price = productCard['price'];

                      return _buildProductCardVertical(isSender, imageUrl, name, price);
                    } else {
                      String messageText = message['message'];
                      return _buildTextMessage(isSender, messageText);
                    }
                  },
                );
              },
            ),
          ),

          // Jika ada produk draft, tampilkan di atas input pesan
          if (widget.draftProductId != null && !_isProductCardSent)
            _buildDraftProductCard(), // Menampilkan kartu produk yang akan dikirim

          // Input untuk mengirim pesan
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan produk dalam draft
  Widget _buildDraftProductCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.draftProductImage ?? '',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.draftProductName ?? 'Nama Produk',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(widget.draftProductPrice),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      CollectionReference messagesRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages');

      // Jika produk belum terkirim, kirim produk draft terlebih dahulu
      if (!_isProductCardSent && widget.draftProductId != null) {
        await messagesRef.add({
          'senderUID': user.uid,
          'message': {
            'image': widget.draftProductImage,
            'name': widget.draftProductName,
            'price': widget.draftProductPrice,
          },
          'type': 'product_card',
          'timestamp': Timestamp.now(),
        });

        _isProductCardSent = true; // Setelah terkirim, update flag
        setState(() {}); // Perbarui tampilan untuk menghapus draft produk
      }

      await messagesRef.add({
        'senderUID': user.uid,
        'message': message,
        'type': 'text',
        'timestamp': Timestamp.now(),
      });

      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'lastMessage': message,
        'lastMessageTimestamp': Timestamp.now(),
      });

      _messageController.clear();
    }
  }

  Widget _buildTextMessage(bool isSender, String messageText) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSender ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isSender ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isSender ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Text(
          messageText,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildProductCardVertical(bool isSender, String imageUrl, String name, double price) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(price),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}


