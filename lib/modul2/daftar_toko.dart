import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class DaftarTokoPage extends StatefulWidget {
  const DaftarTokoPage({super.key});

  @override
  _DaftarTokoPageState createState() => _DaftarTokoPageState();
}

class _DaftarTokoPageState extends State<DaftarTokoPage> {
  final _formKey = GlobalKey<FormState>();
  String? _storeName;
  String? _storeDescription;
  String? _phoneNumber;
  String? _email;
  File? _selectedImage;
  String? _storeLogoUrl;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage(File image) async {
    String fileName = 'store_logos/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);

    TaskSnapshot taskSnapshot = await uploadTask;
    _storeLogoUrl = await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _registerStore() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        if (_selectedImage != null) {
          await _uploadImage(_selectedImage!);
        }

        // Ambil user ID dari pengguna yang sudah login
        String ownerId = FirebaseAuth.instance.currentUser!.uid;

        DocumentReference docRef = await FirebaseFirestore.instance.collection('stores').add({
          'approved': false,
          'email': _email,
          'idstore': '',
          'ownerId': ownerId,
          'phoneNumber': _phoneNumber,
          'product': [],
          'storeDescription': _storeDescription,
          'storeLogo': _storeLogoUrl ?? '',
          'storeName': _storeName,
        });

        await docRef.update({'idstore': docRef.id});

        _showSuccessDialog(); // Tampilkan pop-up setelah berhasil
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selamat'),
          content: const Text('Anda berhasil membuat toko.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pushReplacementNamed(context, '/profile'); // Kembali ke halaman ProfilePage
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Toko'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : const AssetImage('assets/store_image.png')
                                as ImageProvider,
                        child: _selectedImage == null
                            ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Nama Toko',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _storeName = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Toko tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi Toko',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _storeDescription = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi Toko tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nomor Telepon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.number, // Mengatur keyboard hanya untuk angka
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly // Membatasi input hanya angka
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _phoneNumber = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor Telepon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email Toko',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress, // Ini akan menunjukkan keyboard email
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: namatoko@gmail.com',
                    ),
                    onSaved: (value) {
                      // Jika pengguna tidak memasukkan domain, secara otomatis menambahkannya
                      if (value != null && !value.contains('@gmail.com')) {
                        _email = '$value@gmail.com';
                      } else {
                        _email = value;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email Toko tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF319F43),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Daftar Toko'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF319F43)), // Warna hijau #319F43
                ),
              ),
            ),
        ],
      ),
    );
  }
}