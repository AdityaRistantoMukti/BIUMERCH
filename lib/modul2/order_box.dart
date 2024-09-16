  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import "../modul4/history/status_helper.dart";

  class OrderBox extends StatefulWidget {
    final String? imageUrl;
    final String namaBarang;
    final String namaPemesan;
    final String totalPesanan;
    final String priceProduct;
    final String quantity;
    final String opsi;
    final String catatan;
    final String jumlahPembayaran;
    final String? transactionId;
    final String? status;
    final String? category;
    final String storeId; // Tambahkan storeId

 
  const OrderBox({
    Key? key,
    this.imageUrl,
    required this.namaBarang,
    required this.namaPemesan,
    required this.totalPesanan,
    required this.priceProduct,
    required this.quantity,
    required this.opsi,
    required this.catatan,
    required this.jumlahPembayaran,
    this.transactionId,
    this.status,
    this.category,
    required this.storeId,
  }) : super(key: key);

  @override
  _OrderBoxState createState() => _OrderBoxState();
}

class _OrderBoxState extends State<OrderBox> with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isPoActive = false;
  String? selectedTime;
  DateTime? selectedDate;
  String? status;
  File? _selectedImage;
  String? _selectedPhotoPath;
  bool _isLoading = false;

    @override
     void initState() {
    super.initState();
    status = widget.status;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

      // Listen to Firestore for real-time updates
      FirebaseFirestore.instance
          .collection('transaction')
          .doc(widget.transactionId)
          .collection('items')
          .doc(widget.storeId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            List products = data['products'] ?? [];
            for (var product in products) {
              if (product['productName'] == widget.namaBarang) {
                setState(() {
                  status = product['status'];
                });
                break;
              }
            }
          }
        }
      });
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    void _toggleExpanded() {
      setState(() {
        isExpanded = !isExpanded;
        if (isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  Future<void> _selectDate(BuildContext context, void Function(void Function()) dialogSetState) async {
      DateTime now = DateTime.now();
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: isPoActive ? DateTime(2100) : now.add(const Duration(days: 2)),
      );

      if (pickedDate != null && pickedDate != selectedDate) {
        dialogSetState(() {
          selectedDate = pickedDate;
        });
      }
    }

    Future<void> _selectTimeOption(BuildContext context, void Function(void Function()) dialogSetState) async {
      final timeOptions = ['5-15 menit', '20-35 menit', '35-55 menit'];
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView.builder(
            itemCount: timeOptions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(timeOptions[index]),
                onTap: () {
                  dialogSetState(() {
                    selectedTime = timeOptions[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      );
    }
  Future<void> _showAcceptDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text(
                  'Terima Pesanan',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Masukkan estimasi pengiriman:",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.category == "Makanan & Minuman" && !isPoActive)
                      ElevatedButton(
                        onPressed: () => _selectTimeOption(context, setState),
                        child: Text(selectedTime ?? "Pilih Waktu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    if (widget.category != "Makanan & Minuman" || isPoActive)
                      ElevatedButton(
                        onPressed: () => _selectDate(context, setState),
                        child: Text(selectedDate == null
                            ? "Pilih Tanggal"
                            : DateFormat('dd-MM-yyyy').format(selectedDate!)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "PO: ",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Switch(
                          value: isPoActive,
                          onChanged: (value) {Row(
    children: [
      const Text(
        "PO: ",
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      Switch(
        value: isPoActive,
        onChanged: (value) {
          setState(() {
            isPoActive = value;
            selectedTime = null;
            selectedDate = null;
          });
        },
        activeColor: Colors.green,
      ),
      GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "PO (Pre-Order) adalah opsi untuk pesanan yang memerlukan waktu produksi lebih lama. Aktifkan jika barang perlu disiapkan khusus atau membutuhkan waktu pengadaan.",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
      ),
    ],
  );
                            setState(() {
                              isPoActive = value;
                              selectedTime = null;
                              selectedDate = null;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Batal",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String? estimate = selectedDate != null
                          ? DateFormat('dd-MM-yyyy').format(selectedDate!)
                          : selectedTime;

                      if (estimate != null && widget.transactionId != null) {
                        // Get the current user's store ID
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final storeSnapshot = await FirebaseFirestore.instance
                              .collection('stores')
                              .where('ownerId', isEqualTo: user.uid)
                              .get();

                          if (storeSnapshot.docs.isNotEmpty) {
                            String storeId = storeSnapshot.docs.first.id;

                            // Update the items subcollection
                            DocumentReference itemsDocRef = FirebaseFirestore.instance
                                .collection('transaction')
                                .doc(widget.transactionId)
                                .collection('items')
                                .doc(storeId);

                            // Get the current items document
                            DocumentSnapshot itemsDoc = await itemsDocRef.get();

                            if (itemsDoc.exists) {
                              Map<String, dynamic> data = itemsDoc.data() as Map<String, dynamic>;
                              List<dynamic> products = data['products'] as List<dynamic>;

                              // Update the timeEstimate and status for the specific product
                              for (var i = 0; i < products.length; i++) {
                                if (products[i]['productName'] == widget.namaBarang) {
                                  products[i]['timeEstimate'] = estimate;
                                  products[i]['status'] = 'is-preparing';
                                  break;
                                }
                              }

                              // Update the items document with the modified products array
                              await itemsDocRef.update({'products': products});
                            }
                          }
                        }

                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Konfirmasi"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          );
        },
      );
    }


  Future<void> _showDeclineDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Tolak Pesanan',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            content: const Text(
              "Apakah Anda yakin ingin menolak pesanan ini?",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Batal",
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (widget.transactionId != null) {
                    await FirebaseFirestore.instance
                        .collection('transaction')
                        .doc(widget.transactionId)
                        .update({'status': 'declined-by-store'});
                  }
                  Navigator.of(context).pop();
                },
                child: const Text("Tolak"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      );
    }

  Future<void> _showDeliveryConfirmationDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Konfirmasi Pengantaran',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            content: const Text(
              "Apakah makanan sudah siap diantar?",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Batal",
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (widget.transactionId != null) {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final storeSnapshot = await FirebaseFirestore.instance
                          .collection('stores')
                          .where('ownerId', isEqualTo: user.uid)
                          .get();

                      if (storeSnapshot.docs.isNotEmpty) {
                        String storeId = storeSnapshot.docs.first.id;

                        DocumentReference itemsDocRef = FirebaseFirestore.instance
                            .collection('transaction')
                            .doc(widget.transactionId)
                            .collection('items')
                            .doc(storeId);

                        DocumentSnapshot itemsDoc = await itemsDocRef.get();

                        if (itemsDoc.exists) {
                          Map<String, dynamic> data = itemsDoc.data() as Map<String, dynamic>;
                          List<dynamic> products = data['products'] as List<dynamic>;

                          for (var i = 0; i < products.length; i++) {
                            if (products[i]['productName'] == widget.namaBarang) {
                              products[i]['status'] = 'in-delivery';
                              break;
                            }
                          }

                          await itemsDocRef.update({'products': products});
                        }
                      }
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: const Text("Konfirmasi"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      );
    }

@override
Widget build(BuildContext context) {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  return Stack(
    children: [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: StatusHelper.getStatusColor(status ?? ''),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      StatusHelper.getStatusText(status ?? ''),
                      style: TextStyle(
                        color: StatusHelper.getStatusTextColor(status ?? ''),
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: widget.imageUrl != null && widget.imageUrl!.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image, size: 50),
              title: Text(
                widget.namaBarang,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                'Nama Pembeli: ${widget.namaPemesan}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
                onPressed: _toggleExpanded,
              ),
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      'Opsi: ${widget.opsi}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: ${widget.catatan}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Pesanan: ${widget.quantity}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    ),
                    Text(
                      'Harga item: ${formatCurrency.format(int.tryParse(widget.priceProduct) ?? 0)}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jumlah Pembayaran: ${formatCurrency.format(int.tryParse(widget.jumlahPembayaran) ?? 0)}',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    ),
                    const SizedBox(height: 8),
 if (status == 'completed-delivery') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sedang menunggu konfirmasi user..',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
 if (status == 'completed') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pesanan telah dikonfirmasi oleh user.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreen,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),

                    if (status == 'waiting-store-confirmation')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showDeclineDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Tolak'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showAcceptDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Terima'),
                          ),
                        ],
                      ),

                    if (status == 'is-preparing') ...[
                      ElevatedButton(
                        onPressed: () => _showDeliveryConfirmationDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Antar Pesanan'),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (status == 'in-delivery') ...[
                      if (_selectedPhotoPath != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Preview Bukti Foto:',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: () => _showImageDialog(context, _selectedPhotoPath!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedPhotoPath!),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _retakePhoto(context),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Foto Ulang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_selectedPhotoPath != null)
                        ElevatedButton.icon(
                          onPressed: () => _showConfirmationDialog(context, true),
                          icon: const Icon(Icons.check),
                          label: const Text('Konfirmasi dengan Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (_selectedPhotoPath == null) ...[
                        ElevatedButton.icon(
                          onPressed: () => _uploadProofPhoto(context),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Upload Bukti Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showConfirmationDialog(context, false),
                          icon: const Icon(Icons.check),
                          label: const Text('Konfirmasi Tanpa Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
    ],
  );
}

  Future<void> _retakePhoto(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Simpan path foto baru
      setState(() {
        _selectedPhotoPath = image.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diambil ulang. Verifikasi sebelum upload.')),
      );
    }
  }

  void _showConfirmationDialog(BuildContext context, bool withPhoto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Konfirmasi Pesanan',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                withPhoto
                    ? 'Apakah Anda yakin ingin mengonfirmasi pesanan ini dengan bukti foto?'
                    : 'Apakah Anda yakin ingin mengonfirmasi pesanan ini tanpa bukti foto?',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Pastikan semua informasi sudah benar sebelum mengonfirmasi.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });
                if (withPhoto) {
                  await _confirmWithPhoto(context);
                } else {
                  await _confirmDelivery(context);
                }
                setState(() {
                  _isLoading = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Konfirmasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmWithPhoto(BuildContext context) async {
  try {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    if (_selectedPhotoPath != null) {
      File photo = File(_selectedPhotoPath!);

      // Upload photo to Firebase Storage
      String? downloadUrl = await _uploadProofPhotoToStorage(photo);

      if (downloadUrl != null) {
        // Save photo URL and update status to completed-delivery
        await _savePhotoAndCompleteDelivery(downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan dikonfirmasi dengan foto.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah foto.')),
        );
      }
    }
  } finally {
    setState(() {
      _isLoading = false; // Stop loading after the process completes
    });
  }
}



  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadProofPhotoToStorage(File photo) async {
    try {
      // Tentukan lokasi penyimpanan di Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('proof_photos')
          .child('${widget.transactionId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Unggah foto
      await storageRef.putFile(photo);

      // Ambil URL file yang diunggah
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }
  Future<void> _savePhotoAndCompleteDelivery(String downloadUrl) async {
    try {
      // Ambil referensi ke dokumen produk dalam transaksi
      DocumentReference itemsDocRef = FirebaseFirestore.instance
          .collection('transaction')
          .doc(widget.transactionId)
          .collection('items')
          .doc(widget.storeId); // Gunakan storeId

      DocumentSnapshot itemsDoc = await itemsDocRef.get();

      if (itemsDoc.exists) {
        Map<String, dynamic> data = itemsDoc.data() as Map<String, dynamic>;
        List<dynamic> products = data['products'] as List<dynamic>;

        // Cari produk yang sesuai dan tambahkan URL foto ke dalam array produk
        for (var i = 0; i < products.length; i++) {
          if (products[i]['productName'] == widget.namaBarang) {
            products[i]['proofPhotoUrl'] = downloadUrl; // Simpan URL foto
            products[i]['status'] = 'completed-delivery'; // Ubah status menjadi completed-delivery
            break;
          }
        }

        // Perbarui dokumen Firestore
        await itemsDocRef.update({'products': products});
      }
    } catch (e) {
      print('Error saving photo and completing delivery: $e');
    }
  }



 Future<void> _uploadProofPhoto(BuildContext context) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.camera);

  if (image != null) {
    // Show image preview
    setState(() {
      _selectedPhotoPath = image.path;
      _isLoading = true; // Show loading while processing the photo
    });

    // Simulate a delay for upload or processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false; // Stop loading once the image is ready
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto berhasil diambil. Verifikasi sebelum upload.')),
    );
  }
}
  Future<void> _updateProofPhotoUrl(String downloadUrl) async {
    if (widget.transactionId != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storeSnapshot = await FirebaseFirestore.instance
            .collection('stores')
            .where('ownerId', isEqualTo: user.uid)
            .get();

        if (storeSnapshot.docs.isNotEmpty) {
          String storeId = storeSnapshot.docs.first.id;

          DocumentReference itemsDocRef = FirebaseFirestore.instance
              .collection('transaction')
              .doc(widget.transactionId)
              .collection('items')
              .doc(storeId);

          DocumentSnapshot itemsDoc = await itemsDocRef.get();

          if (itemsDoc.exists) {
            Map<String, dynamic> data = itemsDoc.data() as Map<String, dynamic>;
            List<dynamic> products = data['products'] as List<dynamic>;

            for (var i = 0; i < products.length; i++) {
              if (products[i]['productName'] == widget.namaBarang) {
                if (products[i]['proofPhotos'] == null) {
                  products[i]['proofPhotos'] = [];
                }
                products[i]['proofPhotos'].add(downloadUrl); // Tambahkan URL ke array proofPhotos
                products[i]['status'] = 'completed-delivery'; // Ubah status ke completed-delivery
                break;
              }
            }

            await itemsDocRef.update({'products': products});
          }
        }
      }
    }
  }
  Future<void> _confirmDelivery(BuildContext context) async {
    try {
      // Ambil referensi ke dokumen produk dalam transaksi
      DocumentReference itemsDocRef = FirebaseFirestore.instance
          .collection('transaction')
          .doc(widget.transactionId)
          .collection('items')
          .doc(widget.storeId);

      DocumentSnapshot itemsDoc = await itemsDocRef.get();

      if (itemsDoc.exists) {
        Map<String, dynamic> data = itemsDoc.data() as Map<String, dynamic>;
        List<dynamic> products = data['products'] as List<dynamic>;

        // Cari produk yang sesuai dan ubah status menjadi completed-delivery
        for (var i = 0; i < products.length; i++) {
          if (products[i]['productName'] == widget.namaBarang) {
            products[i]['status'] = 'completed-delivery'; // Ubah status
            break;
          }
        }

        // Perbarui dokumen Firestore
        await itemsDocRef.update({'products': products});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan dikonfirmasi tanpa foto.')),
        );
      }
    } catch (e) {
      print('Error confirming delivery without photo: $e');
    }
  }

  }