import 'package:biumerch_mobile_app/WelcomePage.dart';
import 'package:biumerch_mobile_app/category_page.dart';
import 'package:biumerch_mobile_app/chat_page.dart';
import 'package:biumerch_mobile_app/edit_profile_page.dart';
import 'package:biumerch_mobile_app/history_page.dart';
import 'package:biumerch_mobile_app/landing_page.dart';
import 'package:biumerch_mobile_app/login.dart';
import 'package:biumerch_mobile_app/penjual_toko.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'John Doe';
  String _email = 'johndoe@gmail.com';
  String _phone = '081993443055';
  String? _profileImageUrl;

  final String userId = '0895330621478'; // Fixed user ID

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      setState(() {
        _username = data?['username'] ?? 'John Doe';
        _email = data?['email'] ?? 'johndoe@gmail.com';
        _phone = data?['notlp'] ?? '081993443055';
        _profileImageUrl = data?['profilePicture'];
      });
    }
  }

  Future<void> _checkStoreStatus() async {
    // Tampilkan loading overlay dengan warna khusus
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF319F43), // Warna loading sesuai yang diminta
          ),
        );
      },
    );

    try {
      final storeSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: userId)
          .get();

      Navigator.pop(context); // Tutup loading overlay

      if (storeSnapshot.docs.isNotEmpty) {
        // Pengguna sudah memiliki toko
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SellerProfileScreen(storeId: storeSnapshot.docs.first.id)),
        );
      } else {
        // Pengguna belum memiliki toko
        Navigator.pushNamed(context, '/tokobaru');
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading overlay jika terjadi error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa status toko')),
      );
    }
  }

  Future<void> _updateProfile(String username, String email, String phone, String? profileImageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': username,
      'email': email,
      'notlp': phone,
      'profilePicture': profileImageUrl,
    });

    setState(() {
      _username = username;
      _email = email;
      _phone = phone;
      _profileImageUrl = profileImageUrl;
    });
  }

  Future<void> _logout() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('isLoggedInWithoutValidation'); // Jika ada validasi lain
      await FirebaseAuth.instance.signOut(); // Tambahkan ini untuk mengeluarkan pengguna dari Firebase

      // Menggunakan pushAndRemoveUntil untuk memastikan pengguna tidak dapat kembali ke halaman sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()), // Pastikan ini adalah halaman login Anda
        (Route<dynamic> route) => false,
      );
    }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null
                  ? const Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _email,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _phone,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      username: _username,
                      email: _email,
                      phone: _phone,
                      profileImageUrl: _profileImageUrl,
                    ),
                  ),
                );

                if (result != null) {
                  _updateProfile(
                    result['username'],
                    result['email'],
                    result['phone'],
                    result['profileImageUrl'],
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(86, 202, 3, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green),
                        SizedBox(height: 8),
                        Text('Saldo Saya', style: TextStyle(color: Colors.green)),
                        Text('Rp. 1250.000', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _checkStoreStatus,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store, color: Colors.green),
                          SizedBox(height: 8),
                          Text('Toko Saya', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text(
                      'Keranjang Saya',
                      style: TextStyle(color: Color(0xFF194D42)),
                    ),
                    onTap: () {
                      // Handle cart navigation
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text(
                      'Pesanan Saya',
                      style: TextStyle(color: Color(0xFF194D42)),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/formatif');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_center),
                    title: const Text(
                      'Pusat Bantuan',
                      style: TextStyle(color: Color(0xFF194D42)),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/chatpage');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text(
                      'Toko Baru',
                      style: TextStyle(color: Color(0xFF194D42)),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/tokobaru'); // Pindah ke halaman TokoBaruPage
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text(
                      'Keluar',
                      style: TextStyle(color: Color(0xFF194D42)),
                    ),
                    onTap: () {
                      _logout();
                    },
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





