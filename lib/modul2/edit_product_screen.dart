import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final String storeId;

  const EditProductScreen({
    Key? key,
    required this.productId,
    required this.storeId,
    required String productDescription,
  }) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // List untuk menyimpan URL gambar yang ada
  List<String> _imageUrls = [];
  
  // List untuk menyimpan file gambar yang baru diunggah
  List<File?> _images = [];
  
  bool _isLoading = false;
  final _numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final int _maxImageSlots = 6; // Batas maksimal gambar

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _priceController.text = _numberFormat.format(int.parse(doc['price'] ?? '0'));
          _descriptionController.text = doc['description'] ?? '';
          
          // Ambil daftar URL gambar dari Firestore
          _imageUrls = List<String>.from(doc['imageUrls'] ?? []);
          
          // Tambahkan slot untuk gambar yang sudah ada
          _images = List<File?>.filled(_imageUrls.length, null);
        });
      }
    } catch (e) {
      print('Gagal memuat produk: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cleanedPrice = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');

        // Upload images if new ones were selected
        List<String> updatedImageUrls = [..._imageUrls]; // Copy existing URLs
        for (int i = 0; i < _images.length; i++) {
          if (_images[i] != null) {
            final imageUrl = await _uploadImageAndSaveProduct(_images[i]!, widget.productId);
            if (i < updatedImageUrls.length) {
              updatedImageUrls[i] = imageUrl;
            } else {
              updatedImageUrls.add(imageUrl);
            }
          }
        }

        // Update product details
        await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
          'name': _nameController.text,
          'price': cleanedPrice,
          'description': _descriptionController.text,
          'imageUrls': updatedImageUrls, // Update imageUrls
        });

        setState(() {
          _isLoading = false;
        });

        _showSuccessDialog();
      } catch (e) {
        print('Gagal memperbarui produk: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui produk')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
                'Produk berhasil diperbarui',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _uploadImageAndSaveProduct(File image, String productId) async {
    final fileName = '$productId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (index < _images.length) {
          _images[index] = File(pickedFile.path);
        } else {
          _images.add(File(pickedFile.path));
        }
      });
    }
  }

  Widget _buildPhotoUploadButton(int index) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _pickImage(index),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 10),
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
        child: _images.length > index && _images[index] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_images[index]!, fit: BoxFit.cover),
              )
            : (_imageUrls.length > index && _imageUrls[index].isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrls[index], fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.add_photo_alternate_outlined, size: 24),
                      SizedBox(height: 4),
                      Text('Upload', style: TextStyle(fontSize: 12)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    double fontSize = 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: const Color.fromARGB(255, 223, 222, 222),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  _buildTextFormField(
                    label: 'Nama Produk',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama produk tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTextFormField(
                    label: 'Harga Produk',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga produk tidak boleh kosong';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      String formatted = _numberFormat.format(int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')));
                      _priceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTextFormField(
                    label: 'Deskripsi Produk',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text('Foto Produk', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _images.length < _maxImageSlots ? _images.length + 1 : _images.length,
                    itemBuilder: (context, index) {
                      return _buildPhotoUploadButton(index);
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF319F43)),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF62E703),
                  padding: const EdgeInsets.all(16.0),
                  shape: const CircleBorder(),
                ),
                child: const Icon(
                  Icons.save,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
