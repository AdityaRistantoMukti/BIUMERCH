import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductFormScreen extends StatefulWidget {
  final String storeId;

  const ProductFormScreen({super.key, required this.storeId});

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _price = '';
  String _stock = '';
  String _category = 'Makanan & Minuman';
  String _description = '';
  final String _rating = '';
  final List<File?> _images = [null, null, null];
  final _numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  bool _isLoading = false;  // Tambahkan state untuk loading

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.0),
                          ),
                          onSaved: (value) {
                            _productName = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama Produk tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _price = value.replaceAll('.', ''); // Hapus titik
                            });
                          },
                          onSaved: (value) {
                            _price = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harga tidak boleh kosong';
                            }
                            if (int.tryParse(value.replaceAll('.', '')) == null) {
                              return 'Harga tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.0),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            _stock = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Stok tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _category,
                          items: <String>[
                            'Makanan & Minuman',
                            'Elektronik',
                            'Pakaian'
                          ].map((String value) {
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
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12.0),
                          ),
                          maxLines: 3,
                          onSaved: (value) {
                            _description = value ?? '';
                          },
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
                ),
              ],
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
                onPressed: _isLoading ? null : _saveForm, // Nonaktifkan tombol jika sedang loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32), // Gunakan warna hijau neon
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
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

  Widget _buildPhotoUploadButton(int index) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _confirmUpload(index), // Nonaktifkan upload jika sedang loading
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
                Navigator.of(context).pop(false); // Tidak upload
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Konfirmasi upload
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
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
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

    // Dapatkan URL gambar yang diupload
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;  // Tampilkan loading
      });
    
      _formKey.currentState!.save();

      // Generate a new product ID
      final productId = FirebaseFirestore.instance.collection('products').doc().id;

      List<String> imageUrls = [];
      for (File? image in _images) {
        if (image != null) {
          final imageUrl = await _uploadImageAndSaveProduct(image, productId);
          imageUrls.add(imageUrl);
        }
      }

      // Create a map for the product
      Map<String, dynamic> product = {
        'name': _productName,
        'price': _price,
        'stock': _stock,
        'category': _category,
        'description': _description,
        'imageUrls': imageUrls,
        'storeId': widget.storeId,
        'rating': '1.0',
      };

      // Save the product data to Firestore
      await FirebaseFirestore.instance.collection('products').doc(productId).set(product);

      setState(() {
        _isLoading = false;  // Sembunyikan loading
      });

      // Navigate back to the seller's store screen
      Navigator.pop(context, true);  // Kembali dan berikan tanda produk berhasil ditambahkan
    }
  }
}
