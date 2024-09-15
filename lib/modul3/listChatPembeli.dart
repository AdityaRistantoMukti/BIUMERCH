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
  bool _isLoading = true; // This flag will control the global loading state

  @override
  void initState() {
    super.initState();
    _loadChats(); // Function to load chats and manage loading state
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true; // Set loading state to true before fetching data
    });

    // Simulate a small delay to mimic loading process
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false; // Set loading state to false after fetching data
    });
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Chat Toko'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Warna loading hijau
              ),
            )
          : Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .where('buyerUID', isEqualTo: currentUser?.uid) // Hanya room di mana pembeli adalah pengguna yang login
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildNoChatUI();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot roomDocument = snapshot.data!.docs[index];

                        return FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            FirebaseFirestore.instance
                                .collection('products')
                                .doc(roomDocument['productId'])
                                .get(), // Ambil produk
                            FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(roomDocument.id)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .get(), // Ambil pesan terakhir
                          ]),
                          builder: (context, AsyncSnapshot<List<dynamic>> asyncSnapshot) {
                            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                
                              );
                            }

                            // Produk tidak ditemukan
                            if (!asyncSnapshot.data![0].exists) {
                              return const ListTile(
                                title: Text('Produk tidak ditemukan'),
                                subtitle: Text('Produk ini mungkin sudah dihapus'),
                              );
                            }

                            DocumentSnapshot productSnapshot = asyncSnapshot.data![0];
                            QuerySnapshot messageSnapshot = asyncSnapshot.data![1];

                            if (messageSnapshot.docs.isEmpty) {
                              return const SizedBox(); // Tidak ada pesan yang ditampilkan
                            }

                            DocumentSnapshot lastMessageDoc = messageSnapshot.docs.first;
                            String lastMessage = lastMessageDoc['message'];
                            String lastSenderUID = lastMessageDoc['senderUID'];

                            // Ambil data toko
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('stores')
                                  .doc(roomDocument['sellerUID'])
                                  .get(),
                              builder: (context, storeSnapshot) {
                                if (storeSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                   
                                  );
                                }

                                // Jangan tampilkan apapun jika toko tidak ditemukan
                                if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                String storeName = storeSnapshot.data!['storeName'];
                                String? storeLogo = storeSnapshot.data!['storeLogo']; // Gambar profil toko

                                // Ambil pesan yang belum terbaca
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomDocument.id)
                                      .collection('messages')
                                      .where('isRead', isEqualTo: false)
                                      .where('senderUID', isNotEqualTo: currentUser?.uid) // Hanya pesan yang dikirim oleh penjual
                                      .snapshots(),
                                  builder: (context, unreadSnapshot) {
                                    int unreadCount = unreadSnapshot.hasData ? unreadSnapshot.data!.docs.length : 0;

                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Card(
                                            elevation: 4, // Memberikan efek bayangan
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                radius: 25, // Ukuran lingkaran
                                                backgroundImage: storeLogo != null && storeLogo.isNotEmpty
                                                    ? NetworkImage(storeLogo)
                                                    : const AssetImage('assets/default_avatar.png') as ImageProvider, // Gambar default
                                              ),
                                              title: Text(storeName), // Nama toko
                                              subtitle: Row(
                                                children: [
                                                  Text(
                                                    lastSenderUID == currentUser?.uid ? "Anda: " : "$storeName: ",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(lastMessage), // Tampilkan isi pesan terakhir
                                                  ),
                                                ],
                                              ),
                                              trailing: unreadCount > 0
                                                  ? Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '$unreadCount Pesan',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(), // Tidak ada badge jika tidak ada pesan baru
                                              onTap: () {
                                                _markMessagesAsRead(roomDocument.id); // Tandai pesan sebagai sudah dibaca
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
                                            ),
                                          ),
                                        ),
                                      ],
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
              ],
            ),
    );
  }

  // UI untuk menampilkan pesan "Belum ada chat"
  Widget _buildNoChatUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Anda belum berinteraksi dengan toko manapun.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Method untuk menandai pesan sebagai sudah dibaca
  void _markMessagesAsRead(String roomId) async {
    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderUID', isNotEqualTo: currentUser?.uid)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  
  void _deleteChatRoom(String roomId) async {
    QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .get();

    for (var messageDoc in messagesSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageDoc.id)
          .delete();
    }

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
  }
}
