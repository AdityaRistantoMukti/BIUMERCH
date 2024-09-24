import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductFormScreen extends StatefulWidget {
  final String storeId;

  const ProductFormScreen({super.key, required this.storeId, required productId});

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _stock = '';
  String _category = 'Makanan & Minuman';
  String _description = '';
  final String _rating = '';
  final List<File?> _images = [null, null, null];
  bool _isLoading = false;

  final TextEditingController _priceController = TextEditingController();
  final NumberFormat _numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: ' ', decimalDigits: 0);

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView( // Menambahkan scroll view untuk memperpanjang frame utama
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      _buildTextFormField(
                        label: 'Nama Produk',
                        fontSize: 14,  // Mengecilkan ukuran font
                        onSaved: (value) => _productName = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama Produk tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        label: 'Harga',
                        controller: _priceController,
                        fontSize: 14,  // Mengecilkan ukuran font
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleanedValue.isNotEmpty) {
                            int valueInt = int.parse(cleanedValue);
                            String formattedValue = _numberFormat.format(valueInt);
                            _priceController.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(offset: formattedValue.length),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) == null) {
                            return 'Harga tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        label: 'Stok',
                        fontSize: 14,  // Mengecilkan ukuran font
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _stock = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stok tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownFormField(),  // Menggunakan metode untuk dropdown yang serupa dengan form input lainnya
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        label: 'Deskripsi',
                        maxLines: 3,
                        onSaved: (value) => _description = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Foto Produk', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildPhotoUploadButton(0),
                          _buildPhotoUploadButton(1),
                          _buildPhotoUploadButton(2),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF319F43),
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
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Form Input dengan custom fontSize
  Widget _buildTextFormField({
    required String label,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    double fontSize = 16,  // Tambahan untuk custom font size
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: const [
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
            maxLines: maxLines,
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
            style: TextStyle(fontSize: fontSize, color: Colors.black87),
            onSaved: onSaved,
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }

  // DropdownFormField dengan styling yang sama
  Widget _buildDropdownFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
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
          child: DropdownButtonFormField<String>(
            value: _category,
            items: <String>['Makanan & Minuman', 'Perlengkapan', 'Jasa'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _category = value!;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              filled: true,
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Fungsi untuk tombol upload gambar
  Widget _buildPhotoUploadButton(int index) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _confirmUpload(index),
      child: Container(
        width: 100,
        height: 100,
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
        child: _images[index] == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add_photo_alternate_outlined, size: 24),
                  SizedBox(height: 4),
                  Text('Upload', style: TextStyle(fontSize: 12)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_images[index]!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Future<void> _confirmUpload(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Upload'),
          content: const Text('Apakah Anda yakin ingin mengupload foto ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _pickImage(index);
    }
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImageAndSaveProduct(File image, String productId) async {
    final fileName = '$productId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveForm() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    _formKey.currentState!.save();
    final productId = FirebaseFirestore.instance.collection('products').doc().id;

    List<String> imageUrls = [];
    for (File? image in _images) {
      if (image != null) {
        final imageUrl = await _uploadImageAndSaveProduct(image, productId);
        imageUrls.add(imageUrl);
      }
    }

    // Pastikan _stock dikonversi ke tipe int sebelum disimpan
    Map<String, dynamic> product = {
      'name': _productName,
      'price': _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'stock': int.parse(_stock), // Mengubah stock menjadi int
      'category': _category,
      'description': _description,
      'imageUrls': imageUrls,
      'storeId': widget.storeId,
      'rating': '1.0',
    };

    await FirebaseFirestore.instance.collection('products').doc(productId).set(product);

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context, true);
  }
}
}
