import 'package:biumerch_mobile_app/modul3/chat_penjual_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListChat extends StatefulWidget {
  final String storeId;

  const ListChat({super.key, required this.storeId});

  @override
  _ListChatState createState() => _ListChatState();
}

class _ListChatState extends State<ListChat> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('sellerUID', isEqualTo: widget.storeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot roomDocument = snapshot.data!.docs[index];

              // Check if the product associated with the chat room exists
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(roomDocument['productId'])
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // If the product does not exist, delete the chat room
                  if (!productSnapshot.data!.exists) {
                    _deleteChatRoom(roomDocument.id);
                    return const SizedBox(); // Don't display deleted rooms
                  }

                  // If the product exists, proceed with the normal chat list display
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomDocument.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
                        return const SizedBox(); // If no messages, show nothing
                      }

                      DocumentSnapshot lastMessageDoc = messageSnapshot.data!.docs.first;
                      String lastMessage = lastMessageDoc['message'];
                      String lastSenderUID = lastMessageDoc['senderUID'];

                      // Get buyer data
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(roomDocument['buyerUID'])
                            .get(),
                        builder: (context, buyerSnapshot) {
                          if (!buyerSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                          String buyerName = buyerSnapshot.data!['username'];

                          // Fetch the store name
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('stores')
                                .doc(widget.storeId) // Fetch using storeId
                                .get(),
                            builder: (context, storeSnapshot) {
                              if (!storeSnapshot.hasData) return const SizedBox();

                              String storeName = storeSnapshot.data!['storeName'];

                              String senderLabel = lastSenderUID == currentUser?.uid ? "Anda" : "Pembeli";

                              return ListTile(
                                title: Text(buyerName),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      "$senderLabel: ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(lastMessage),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to the individual chat screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HalamanChatPenjual(
                                        roomId: roomDocument.id,
                                        buyerUID: roomDocument['buyerUID'],
                                        sellerUID: roomDocument['sellerUID'],
                                        storeName: storeName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Method to delete chat room when associated product is deleted
  void _deleteChatRoom(String roomId) async {
    QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .get();

    // Delete all messages in the room
    for (var messageDoc in messagesSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageDoc.id)
          .delete();
    }

    // Delete the room itself
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
  }
}
