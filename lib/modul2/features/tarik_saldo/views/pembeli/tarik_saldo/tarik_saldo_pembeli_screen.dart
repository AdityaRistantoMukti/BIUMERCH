import 'dart:async';
import '/modul2/features/tarik_saldo/controllers/tarik_saldo_pembeli_controller.dart';
import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/bank_dropdown_widget.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nama_penerima_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nominal_penarikan_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nomor_rekening_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/total_pendapatan_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TarikSaldoPembeliScreen extends StatefulWidget {
  const TarikSaldoPembeliScreen({super.key});

  @override
  _TarikSaldoPembeliScreenState createState() =>
      _TarikSaldoPembeliScreenState();
}

class _TarikSaldoPembeliScreenState extends State<TarikSaldoPembeliScreen> {
  final TarikSaldoPembeliController _controller =
      TarikSaldoPembeliController(); // Inisialisasi controller

  Timer? _debounce;
  String? selectedBank;
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();
  final TextEditingController _nominalPenarikanController =
      TextEditingController();
  final _formatCurrency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
  bool _isLoading = false;
  int balance = 0;
  int biayaAdmin = 0;
  int uangDiterima = 0;

  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _namaPenerimaController.dispose();
    _nomorRekeningController.dispose();
    _nominalPenarikanController.dispose();
    super.dispose();
  }

  void _resetFields() {
    setState(() {
      _namaPenerimaController.clear();
      _nomorRekeningController.clear();
      _nominalPenarikanController.clear();
      selectedBank = null;
      biayaAdmin = 0;
      uangDiterima = 0;
    });
  }

  final List<Map<String, dynamic>> banks = [
    {
      'name': 'Bank Central Asia (BCA)',
      'type': 'bank', // Tambahkan tipe bank
      'logo': 'assets/images/bca_logo.jpeg',
    },
    {
      'name': 'Bank Mandiri',
      'type': 'bank',
      'logo': 'assets/images/mandiri_logo.jpeg',
    },
    {
      'name': 'Bank Negara Indonesia (BNI)',
      'type': 'bank', // Tambahkan tipe virtual account
      'logo': 'assets/images/bni_logo.jpeg',
    },
    {
      'name': 'Bank Rakyat Indonesia (BRI)',
      'type': 'bank', // Tambahkan tipe virtual account
      'logo': 'assets/images/bri_logo.jpeg',
    },
    {
      'name': 'Bank Tabungan Negara (BTN)',
      'type': 'bank', // Tambahkan tipe virtual account
      'logo': 'assets/images/btn_logo.jpeg',
    },
    {
      'name': 'BCA VirtualAccount (GoPay)',
      'type': 'virtual_account', // Tambahkan tipe virtual account
      'logo': 'assets/images/gopay_logo.jpeg',
    },
    {
      'name': 'BCA VirtualAccount (DANA)',
      'type': 'virtual_account', // Tambahkan tipe virtual account
      'logo': 'assets/images/dana_logo.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Nutino',
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 0.5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/historyWithdrawal.png',
                    width: 30,
                    height: 30,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/tarik_saldo_riwayat_pembeli');
                  },
                ),
              ),
              const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser?.uid)
      .snapshots(),
  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return const Text('Error saat mengambil data');
    }
    if (snapshot.hasData && snapshot.data != null) {
      var userData = snapshot.data!.data() as Map<String, dynamic>?;

      // Safely handle both int and double for balance
      balance = (userData?['balance'] ?? 0).toDouble().toInt(); // Convert to double then to int

      return TotalPendapatanWidget(totalPendapatan: balance);
    } else {
      return const Text('Data tidak ditemukan');
    }
  },
),

              const SizedBox(height: 80),
              NamaPenerimaField(controller: _namaPenerimaController),
              const SizedBox(height: 20),
              BankDropdownWidget(
                banks: banks,
                selectedBank: selectedBank,
                onChanged: (value) {
                  setState(() {
                    selectedBank = value;
                    _nomorRekeningController.clear();

                    var selectedBankName = banks.firstWhere(
                        (bank) => bank['name'] == selectedBank)['name'];

                    if (selectedBankName == 'Bank Central Asia (BCA)') {
                      biayaAdmin = 0;
                    } else {
                      var bankType = banks.firstWhere(
                          (bank) => bank['name'] == selectedBank)['type'];
                      if (bankType == 'bank') {
                        biayaAdmin = 2500;
                      } else if (bankType == 'virtual_account') {
                        biayaAdmin = 1000;
                      }
                    }

                    if (_nominalPenarikanController.text.isNotEmpty) {
                      final nominal = int.parse(_nominalPenarikanController.text
                          .replaceAll('Rp. ', '')
                          .replaceAll('.', ''));
                      uangDiterima = nominal - biayaAdmin;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              NomorRekeningField(
                controller: _nomorRekeningController,
                onChanged: (value) {
                  _nomorRekeningController.value = TextEditingValue(
                    text: value,
                    selection: TextSelection.fromPosition(
                      TextPosition(offset: value.length),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              NominalPenarikanField(
                controller: _nominalPenarikanController,
                formatCurrency: _formatCurrency,
                onChanged: (value) {
                  _onNominalPenarikanChanged(value);

                  if (_debounce?.isActive ?? false) {
                    _debounce!.cancel();
                  }

                  _debounce = Timer(const Duration(seconds: 2), () {
                    if (value.isNotEmpty && selectedBank != null) {
                      try {
                        final nominal = int.parse(
                            value.replaceAll('Rp. ', '').replaceAll('.', ''));
                        setState(() {
                          uangDiterima = nominal - biayaAdmin;
                        });
                      } catch (e) {
                        setState(() {
                          uangDiterima = 0;
                        });
                      }
                    } else {
                      setState(() {
                        uangDiterima = 0;
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              if (selectedBank != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Biaya Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedBank == 'Bank Central Asia (BCA)'
                            ? 'Tanpa biaya admin'
                            : _formatCurrency.format(biayaAdmin),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (selectedBank != null &&
                  _nominalPenarikanController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Uang Diterima',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatCurrency.format(uangDiterima),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 50,
            maxHeight: 50,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF62E703),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _validateAndSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Tarik Saldo',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNominalPenarikanChanged(String value) {
    String newValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedValue =
        '${_formatCurrency.format(int.parse(newValue.isEmpty ? '0' : newValue))}';
    _nominalPenarikanController.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formattedValue.length),
      ),
    );
  }

  // Ubah untuk menggunakan controller pembeli
  void _validateAndSubmit() async {
    if (_namaPenerimaController.text.isEmpty ||
        selectedBank == null ||
        _nomorRekeningController.text.isEmpty ||
        _nominalPenarikanController.text == 'Rp. ') {
      _showWarningDialog("Form tidak lengkap.");
      return;
    }

  final nominal = double.parse(_nominalPenarikanController.text
    .replaceAll('Rp. ', '')
    .replaceAll('.', ''))
    .toInt();  // Safely cast to int

if (nominal > balance) {
  _showWarningDialog("Saldo tidak mencukupi.");
  return;
}


    setState(() {
      _isLoading = true;
    });

    final model = TarikSaldoModel(
      transactorId: currentUser?.uid ?? '', // Gunakan UID pengguna yang login
      namaPenerima: _namaPenerimaController.text,
      nomorRekening: _nomorRekeningController.text,
      provider: selectedBank!,
      nominal: nominal,
      biayaAdmin: biayaAdmin,
      uangDiterima: uangDiterima,
      status: "pending",
      tanggal: DateTime.now(),
      type: "pembeli",
      buktiBayar: "",
      alasan: "",
    );

    // Gunakan controller untuk mengirimkan transaksi penarikan saldo
    await _controller.tarikSaldo(context, model, balance, _resetFields);

    setState(() {
      _isLoading = false;
    });
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Peringatan"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
