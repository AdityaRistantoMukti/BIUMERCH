import 'package:biumerch_mobile_app/bottom_navigation.dart';
import 'package:biumerch_mobile_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HalamanChatPenjual extends StatefulWidget {
  final String roomId;
  final String buyerUID;
  final String sellerUID;

  const HalamanChatPenjual({
    super.key,
    required this.roomId,
    required this.buyerUID,
    required this.sellerUID,
  });

  @override
  _HalamanChatPenjualState createState() => _HalamanChatPenjualState();
}

class _HalamanChatPenjualState extends State<HalamanChatPenjual> {
  final int _selectedIndex = 0;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  void _onItemTapped(int index) {
    Widget page;

    switch (index) {
      case 0:
        page = BottomNavigation();
        break;
      case 1:
        page = BottomNavigation(selectedIndex: 1);
        break;
      case 2:
        page = BottomNavigation(selectedIndex: 2);
        break;
      case 3:
        page = BottomNavigation(selectedIndex: 3);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final opacityAnimation = animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ).drive(
            Tween<double>(begin: 0.0, end: 1.0),
          );
          return FadeTransition(opacity: opacityAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 10),
      ),
    );
  }

  void _sendMessage({String? existingMessageId}) async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      CollectionReference messagesRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages');

      String senderUID = user.uid; // UID user yang sedang login

      if (existingMessageId != null) {
        // Update existing message
        await messagesRef.doc(existingMessageId).update({
          'senderUID': senderUID,
          'message': message,
          'timestamp': Timestamp.now(),
        });
      } else {
        // Add new message
        await messagesRef.add({
          'senderUID': senderUID,
          'message': message,
          'timestamp': Timestamp.now(),
        });
      }

      // Update last message in room
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'lastMessage': message,
        'lastMessageTimestamp': Timestamp.now(),
      });

      _messageController.clear();
    }
  }

  void _listenForMessages() {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var messageData = change.doc.data();

          if (messageData != null) {
            String senderId = messageData['senderUID'] ?? '';

            // Jika senderId bukan milik penjual (pesan diterima oleh penjual)
            if (senderId != widget.sellerUID) {
              _showNotification("Pesan Baru", messageData['message'] ?? '');
            }
          }
        }
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'chat_notifications',
      'Chat Notifications',
      channelDescription: 'Notifikasi untuk pesan chat baru dari pembeli atau penjual',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan Penjual'),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                    bool isSender = message['senderUID'] == currentUser?.uid;

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: isSender ? Radius.circular(12) : Radius.circular(0),
                            bottomRight: isSender ? Radius.circular(0) : Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                            color: isSender ? Colors.black : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/beranda.svg',
              width: 24,
              height: 24,
              color: _selectedIndex == 0 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/kategori.svg',
              width: 24,
              height: 24,
              color: _selectedIndex == 1 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/NavigationBar/riwayat.png',
              width: 24,
              height: 24,
              color: _selectedIndex == 2 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/NavigationBar/profil.svg',
              width: 30,
              height: 30,
              color: _selectedIndex == 3 ? Colors.grey[800] : Colors.grey[400],
            ),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey[800],
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
