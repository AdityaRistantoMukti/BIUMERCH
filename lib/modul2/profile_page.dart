import '/modul1/WelcomePage.dart';
import '/modul2/edit_profile_page.dart';
import '/modul2/penjual_toko.dart';
import '/utils/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'User';
  String _email = '';
  String _phone = '';
  String? _profileImageUrl;
  double _balance = 0.0; // Add a field for balance
  bool _isLoggedIn = false;
  bool _isCaptchaVerified = false;  // Tambahkan status verifikasi captcha
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCaptchaVerified = prefs.getBool('isCaptchaVerified') ?? false;
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null && isCaptchaVerified;
    });
  }

  Future<void> _checkStoreStatus() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF319F43),
          ),
        );
      },
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storeSnapshot = await FirebaseFirestore.instance
            .collection('stores')
            .where('ownerId', isEqualTo: user.uid)
            .get();

        Navigator.pop(context);

        if (storeSnapshot.docs.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SellerProfileScreen(storeId: storeSnapshot.docs.first.id)),
          );
        } else {
          Navigator.pushNamed(context, '/tokobaru');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa status toko')),
      );
    }
  }

  Future<void> _updateProfile(String username, String email, String phone, String? profileImageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': username,
        'email': email,
        'phone': phone,
        'profilePicture': profileImageUrl,
      });

      setState(() {
        _username = username;
        _email = email;
        _phone = phone;
        _profileImageUrl = profileImageUrl;
      });
    }
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: _isLoggedIn
          ? AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
            )
          : null,
      body: _isLoggedIn
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid) // Ambil UID user yang sedang login
                  .snapshots(), // Menggunakan Stream untuk mengambil data secara real-time
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var userData = snapshot.data?.data() as Map<String, dynamic>?;
                _username = userData?['username'] ?? 'User';
                _email = userData?['email'] ?? '';
                _phone = userData?['phone'] ?? '';
                _profileImageUrl = userData?['profilePicture'];
                _balance = (userData?['balance'] ?? 0).toDouble();

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
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
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _phone,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/tarik_saldo_pembeli');
                                },
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 100),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.account_balance_wallet, color: Colors.green),
                                      const SizedBox(height: 8),
                                      const Text('Saldo Saya', style: TextStyle(color: Colors.green)),
                                      Text(
                                        formatRupiah(_balance.toInt()), // Convert to int for formatting
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
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
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.receipt),
                              title: const Text(
                                'Riwayat Pesanan',
                                style: TextStyle(color: Color(0xFF194D42)),
                              ),
                              onTap: () {
                                Navigator.pushNamed(context, '/riwayat');
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
                              leading: const Icon(Icons.exit_to_app),
                              title: const Text(
                                'Keluar',
                                style: TextStyle(color: Color(0xFF194D42)),
                              ),
                              onTap: _confirmLogout,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Silahkan Login Terlebih Dahulu',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
            ),
    );
  }

  String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
  }

}
