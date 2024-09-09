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
  final User? currentUser = FirebaseAuth.instance.currentUser; // Mendapatkan user yang sedang login

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

              // Stream untuk pesan terakhir dalam room
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

                  // Ambil data pembeli (buyer) dari UID
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(roomDocument['buyerUID']).get(),
                    builder: (context, buyerSnapshot) {
                      if (!buyerSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                      String buyerName = buyerSnapshot.data!['username'];

                      // Tentukan label apakah pengirim terakhir adalah Anda atau Pembeli
                      String senderLabel = lastSenderUID == currentUser?.uid ? "Anda" : "Pembeli";

                      return ListTile(
                        title: Text(buyerName),
                        subtitle: Row(
                          children: [
                            Text(
                              "$senderLabel: ", // Label pengirim apakah Anda atau Pembeli
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
      ),
    );
  }
}
