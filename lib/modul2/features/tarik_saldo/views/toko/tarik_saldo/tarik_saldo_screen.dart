import 'dart:async';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/bank_dropdown_widget.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nama_penerima_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nominal_penarikan_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/nomor_rekening_field.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo/widget/total_pendapatan_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/tarik_saldo_controller.dart';
import '../../../models/tarik_saldo_model.dart';
import '../../../repositories/toko/tarik_saldo_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TarikSaldoScreen extends StatefulWidget {
  const TarikSaldoScreen({super.key});

  @override
  TarikSaldoScreenState createState() => TarikSaldoScreenState();
}

class TarikSaldoScreenState extends State<TarikSaldoScreen> {
  Timer? _debounce;
  String? selectedBank;
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();
  final TextEditingController _nominalPenarikanController =
      TextEditingController();
  final TarikSaldoController _controller = TarikSaldoController();
  final TarikSaldoRepository _repository =
      TarikSaldoRepository(); // Inisialisasi repository
  final _formatCurrency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
  bool _isLoading = false;
  int balance = 0; // Tambahkan variabel untuk menyimpan balance
  int biayaAdmin = 0; // Variabel untuk biaya admin
  int uangDiterima = 0; // Variabel untuk uang yang diterima

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

  // Definisikan kembali daftar bank dan virtual account
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
                  offset: const Offset(0, 1), // changes position of shadow
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
                    Navigator.pushNamed(context, '/tarik_saldo_riwayat');
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Gunakan StreamBuilder untuk memantau perubahan data secara real-time
              StreamBuilder<DocumentSnapshot>(
                stream: _repository.getTotalPendapatanStream(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Tampilkan loading saat menunggu data
                  }
                  if (snapshot.hasError) {
                    return const Text('Error saat mengambil data');
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    var storeData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    balance = storeData['balance'] ??
                        0; // Ambil balance dari Firestore dan simpan
                    return TotalPendapatanWidget(
                        totalPendapatan: balance); // Tampilkan balance
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
                      biayaAdmin = 0; // Tidak ada biaya admin untuk BCA
                    } else {
                      // Ambil tipe bank berdasarkan pilihan bank
                      var bankType = banks.firstWhere(
                          (bank) => bank['name'] == selectedBank)['type'];

                      if (bankType == 'bank') {
                        biayaAdmin = 2500; // Biaya admin untuk bank lainnya
                      } else if (bankType == 'virtual_account') {
                        biayaAdmin = 1000; // Biaya admin untuk virtual account
                      }
                    }

                    // Update uang yang diterima jika nominal penarikan sudah diisi
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

                  // Cancel debounce jika ada
                  if (_debounce?.isActive ?? false) {
                    _debounce!.cancel();
                  }

                  // Set debounce untuk mencegah reload cepat
                  _debounce = Timer(const Duration(seconds: 2), () {
                    // Pastikan input tidak kosong dan selectedBank tidak null
                    if (value.isNotEmpty && selectedBank != null) {
                      // Pastikan string di-convert ke integer hanya jika valid
                      try {
                        final nominal = int.parse(
                            value.replaceAll('Rp. ', '').replaceAll('.', ''));
                        setState(() {
                          uangDiterima = nominal - biayaAdmin;
                        });
                      } catch (e) {
                        // Handle jika parsing error (contohnya jika string kosong atau invalid)
                        setState(() {
                          uangDiterima = 0; // atau nilai default lainnya
                        });
                      }
                    } else {
                      setState(() {
                        uangDiterima =
                            0; // Uang diterima jadi 0 jika input kosong
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Tampilkan field biaya admin jika sudah ada pilihan bank
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

              // Tampilkan field uang diterima
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

  // Fungsi untuk memformat nominal penarikan
  void _onNominalPenarikanChanged(String value) {
    String newValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedValue =
        '${_formatCurrency.format(int.parse(newValue.isEmpty ? '0' : newValue))}';

    // Update controller tanpa memanggil setState
    _nominalPenarikanController.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formattedValue.length),
      ),
    );
  }

  // Fungsi untuk validasi form dan submit
  void _validateAndSubmit() async {
    if (_namaPenerimaController.text.isEmpty ||
        selectedBank == null ||
        _nomorRekeningController.text.isEmpty ||
        _nominalPenarikanController.text == 'Rp. ') {
      _showWarningDialog("Form tidak lengkap.");
      return;
    }

    final nominal = int.parse(_nominalPenarikanController.text
        .replaceAll('Rp. ', '')
        .replaceAll('.', ''));

    // Validasi: Cek apakah nominal lebih besar dari balance
    if (nominal > balance) {
      _showWarningDialog("Saldo tidak mencukupi.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final model = TarikSaldoModel(
      transactorId: '', // idStore akan diambil di controller
      namaPenerima: _namaPenerimaController.text,
      nomorRekening: _nomorRekeningController.text,
      provider: selectedBank!,
      nominal: nominal,
      biayaAdmin: biayaAdmin,
      uangDiterima: uangDiterima,
      status: "pending",
      tanggal: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      type: "penjual",
      buktiBayar: "",
      alasan: "",
    );

    await _controller.tarikSaldo(context, model, balance, _resetFields);

    setState(() {
      _isLoading = false;
    });
  }

  // Fungsi untuk menampilkan dialog peringatan
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
