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

        _showSuccessDialog();
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
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profile');
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
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : const AssetImage('assets/store_image.png') as ImageProvider,
                          child: Stack(
                            children: [
                              if (_selectedImage == null)
                                const Center(
                                  child: Icon(Icons.camera_alt, size: 50, color: Colors.white),
                                ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.edit, color: const Color(0xFF62E703)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextFormField(
                    label: 'Nama Toko',
                    onSaved: (value) => _storeName = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Toko tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'No. Telpon',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSaved: (value) => _phoneNumber = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor Telepon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) {
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
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Deskripsi Toko', // Deskripsi toko dipindahkan ke bagian paling bawah
                    maxLines: 3,
                    onSaved: (value) => _storeDescription = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi Toko tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildShadedButton(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62E703)),
                ),
              ),
            ),
        ],
      ),
    );
  }

AppBar _buildAppBar() {
  return AppBar(
    title: const Text(
      'Daftar Toko',
      style: TextStyle(color: Colors.black), // Warna teks hitam
    ),
    centerTitle: true,
    backgroundColor: Colors.white,
    elevation: 4, // Sesuaikan dengan kebutuhan
    shadowColor: Colors.grey.withOpacity(0.5), // Warna shadow agar terlihat floating
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(15), // Memberikan lengkungan di bagian bawah AppBar
      ),
    ),
  );
}


  Widget _buildShadedButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _registerStore,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF62E703),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Daftar Toko', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              fillColor: Colors.grey[200],
              filled: true,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            onSaved: onSaved,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
