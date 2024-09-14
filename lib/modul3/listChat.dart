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
        title: const Text('Daftar Chat Pembeli'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Green loading indicator
              ),
            )
          : Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .where('sellerUID', isEqualTo: widget.storeId) // Only show rooms where the seller is the current store
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
                                .get(), // Get product info
                            FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(roomDocument.id)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .get(), // Get last message
                          ]),
                          builder: (context, AsyncSnapshot<List<dynamic>> asyncSnapshot) {
                            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                               
                              );
                            }

                            // Product not found
                            if (!asyncSnapshot.data![0].exists) {
                              return const ListTile(
                                title: Text('Produk tidak ditemukan'),
                                subtitle: Text('Produk ini mungkin sudah dihapus'),
                              );
                            }

                            DocumentSnapshot productSnapshot = asyncSnapshot.data![0];
                            QuerySnapshot messageSnapshot = asyncSnapshot.data![1];

                            if (messageSnapshot.docs.isEmpty) {
                              return const SizedBox(); // No messages to show
                            }

                            DocumentSnapshot lastMessageDoc = messageSnapshot.docs.first;
                            String lastMessage = lastMessageDoc['message'];
                            String lastSenderUID = lastMessageDoc['senderUID'];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(roomDocument['buyerUID'])
                                  .get(), // Get buyer info
                              builder: (context, buyerSnapshot) {
                                if (buyerSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                   
                                  );
                                }

                                // Only delete the room if the buyer doesn't exist in Firebase
                                if (!buyerSnapshot.hasData || !buyerSnapshot.data!.exists) {
                                  _deleteChatRoom(roomDocument.id);
                                  return const SizedBox.shrink(); // Return nothing if buyer doesn't exist
                                }

                                String buyerName = buyerSnapshot.data!['username'];
                                String? profilePicture = buyerSnapshot.data!['profilePicture']; // Buyer's profile image

                                // Get unread messages for the seller
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomDocument.id)
                                      .collection('messages')
                                      .where('isRead', isEqualTo: false)
                                      .where('senderUID', isNotEqualTo: currentUser?.uid) // Unread messages from buyer
                                      .snapshots(),
                                  builder: (context, unreadSnapshot) {
                                    int unreadCount = unreadSnapshot.hasData ? unreadSnapshot.data!.docs.length : 0;

                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Card(
                                            elevation: 4, // Shadow effect
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                radius: 25, // Profile image size
                                                backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                                    ? NetworkImage(profilePicture)
                                                    : const AssetImage('assets/default_avatar.png') as ImageProvider, // Default avatar
                                              ),
                                              title: Text(buyerName), // Buyer's name
                                              subtitle: Row(
                                                children: [
                                                  Text(
                                                    lastSenderUID == currentUser?.uid ? "Anda: " : "$buyerName: ",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(lastMessage), // Display last message
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
                                                  : const SizedBox.shrink(), // No unread badge if there are no unread messages
                                              onTap: () {
                                                _markMessagesAsRead(roomDocument.id); // Mark messages as read when clicked
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => HalamanChatPenjual(
                                                      roomId: roomDocument.id,
                                                      buyerUID: roomDocument['buyerUID'],
                                                      sellerUID: roomDocument['sellerUID'],
                                                      storeName: buyerName,
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

  // UI for "No chats" state
  Widget _buildNoChatUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Anda belum berinteraksi dengan siapapun.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Mark messages as read
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

  // Function to delete chat rooms only if the buyer doesn't exist
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
