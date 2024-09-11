import 'package:biumerch_mobile_app/modul3/chat_penjual_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListChatPembeli extends StatefulWidget {
  const ListChatPembeli({super.key});

  @override
  _ListChatPembeliState createState() => _ListChatPembeliState();
}

class _ListChatPembeliState extends State<ListChatPembeli> {
  final User? currentUser = FirebaseAuth.instance.currentUser; // Mendapatkan user yang sedang login

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Chat Toko'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('buyerUID', isEqualTo: currentUser?.uid) // Hanya room di mana pembeli adalah pengguna yang login
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot roomDocument = snapshot.data!.docs[index];

              // Check if the product associated with the chat room still exists
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
                    return const SizedBox(); // Do not show the room if deleted
                  }

                  // Stream for the last message in the room
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
                        return const SizedBox(); // Jika tidak ada pesan
                      }

                      DocumentSnapshot lastMessageDoc = messageSnapshot.data!.docs.first;
                      String lastMessage = lastMessageDoc['message'];
                      String lastSenderUID = lastMessageDoc['senderUID'];

                      // Ambil data nama toko (storeName) dari koleksi stores berdasarkan sellerUID
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('stores')
                            .doc(roomDocument['sellerUID'])
                            .get(),
                        builder: (context, storeSnapshot) {
                          if (!storeSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                          String storeName = storeSnapshot.data!['storeName'];

                          // Tentukan label apakah pengirim terakhir adalah Anda atau Toko
                          String senderLabel = lastSenderUID == currentUser?.uid ? "Anda" : storeName;

                          return ListTile(
                            title: Text(storeName), // Nama toko
                            subtitle: Row(
                              children: [
                                Text(
                                  "$senderLabel: ", // Label pengirim apakah Anda atau Toko
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(lastMessage), // Tampilkan isi pesan terakhir
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanChatPenjual(
                                    roomId: roomDocument.id,
                                    buyerUID: roomDocument['buyerUID'],
                                    sellerUID: roomDocument['sellerUID'],
                                    storeName: storeName, // Pass storeName here
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
