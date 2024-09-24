import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  final String storeName;
  final String email;
  final String phoneNumber;
  String imagePath;
  final String storeId; // Tambahkan ini untuk menerima storeId

  EditProfileScreen({
    super.key,
    required this.storeName,
    required this.email,
    required this.phoneNumber,
    required this.imagePath,
    required this.storeId, // Inisialisasi storeId
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaTokoController;
  late TextEditingController _emailController;
  late TextEditingController _noHpController;
  File? _imageFile;
  final String storeId = 'storeid1'; // ID Toko yang tetap
  bool _isLoading = false; // Tambahkan state untuk loading

  @override
  void initState() {
    super.initState();
    _namaTokoController = TextEditingController(text: widget.storeName);
    _emailController = TextEditingController(text: widget.email);
    _noHpController = TextEditingController(text: widget.phoneNumber);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      widget.imagePath = 'assets/gambar/user.jpg';
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('store_logos/$storeId.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Gagal mengunggah gambar: $e');
      return null;
    }
  }

  Future<void> _saveProfileToFirebase(String storeName, String email, String phoneNumber, String imagePath) async {
    try {
      await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).update({
        'storeName': storeName,
        'email': email,
        'phoneNumber': phoneNumber,
        'storeLogo': imagePath,
      });

      print('Data profil toko berhasil disimpan di Firebase.');
    } catch (e) {
      print('Gagal menyimpan data profil toko: $e');
    }
  }

  Future<void> _showSuccessDialog() async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF319F43),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Profil Berhasil Diperbarui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Tutup dialog
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: const Color(0xFF319F43),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    },
  );
}



  Future<void> _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true; // Mulai loading
    });

    String? uploadedImagePath = widget.imagePath;
    if (_imageFile != null) {
      uploadedImagePath = await _uploadImage(_imageFile!);
    }

    if (uploadedImagePath != null) {
      await _saveProfileToFirebase(
        _namaTokoController.text,
        _emailController.text,
        _noHpController.text.isEmpty ? widget.phoneNumber : _noHpController.text,
        uploadedImagePath,
      );

      // Tampilkan dialog sukses dan tunggu sampai dialog ditutup
      await _showSuccessDialog();

      // Setelah dialog sukses ditutup, kembali ke halaman sebelumnya
      Navigator.pop(context, {
        'name': _namaTokoController.text,
        'email': _emailController.text,
        'phone': _noHpController.text.isEmpty ? widget.phoneNumber : _noHpController.text,
        'imagePath': uploadedImagePath,
      });
    } else {
      print('Gagal mengunggah gambar');
    }

    setState(() {
      _isLoading = false; // Selesai loading
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: const Color.fromARGB(255, 33, 218, 64),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage, // Nonaktifkan saat loading
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5, // Shading lebih kuat
                            blurRadius: 7,
                            offset: const Offset(0, 4), // Mengatur posisi bayangan
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55, // Membesarkan sedikit radius
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.imagePath.startsWith('http')
                                ? NetworkImage(widget.imagePath)
                                : AssetImage(widget.imagePath)) as ImageProvider,
                        child: _imageFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Color.fromARGB(255, 237, 241, 238),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_imageFile != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _clearImage,
                      child: const Text('Hapus Gambar'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Nama Toko',
                    controller: _namaTokoController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan nama toko';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Email',
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'No HP',
                    controller: _noHpController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && !RegExp(r'^[0-9-]+$').hasMatch(value)) {
                        return 'Masukkan nomor HP yang valid';
                      }
                      return null;
                    },
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
                  color: Color(0xFF319F43), // Warna hijau sesuai permintaan
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile, // Nonaktifkan tombol saat loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32), // Warna hijau neon
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF319F43), // Warna hijau sesuai permintaan
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.grey,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              fillColor: Colors.grey[200],
              filled: true,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    super.dispose();
  }
}
