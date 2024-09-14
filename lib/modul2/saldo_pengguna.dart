import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import untuk NumberFormat
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TarikSaldoScreen(),
    );
  }
}

class TarikSaldoScreen extends StatefulWidget {
  @override
  _TarikSaldoScreenState createState() => _TarikSaldoScreenState();
}

class _TarikSaldoScreenState extends State<TarikSaldoScreen> {
  String? selectedBank;
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorRekeningController = TextEditingController();
  final TextEditingController _nominalPenarikanController = TextEditingController();
  bool _isLoading = false; // Menambahkan indikator loading
  final _formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0); // Remove symbol for formatting

  // Daftar bank dan e-wallet beserta format nomor rekening
  final List<Map<String, dynamic>> banks = [
    {'name': 'Bank Central Asia (BCA)', 'icon': Icons.account_balance, 'color': Colors.blue, 'logo': 'assets/images/bca_logo.jpeg', 'pattern': [10]},
    {'name': 'Bank Mandiri', 'icon': Icons.account_balance_wallet, 'color': Colors.yellow, 'logo': 'assets/images/mandiri_logo.jpeg', 'pattern': [3, 3, 3, 4]}, // 13 digit
    {'name': 'Bank Negara Indonesia (BNI)', 'icon': Icons.attach_money, 'color': Colors.orange, 'logo': 'assets/images/bni_logo.jpeg', 'pattern': [4, 4, 2, 3]}, // 13 digit
    {'name': 'Bank Rakyat Indonesia (BRI)', 'icon': null, 'color': Colors.red, 'logo': 'assets/images/bri_logo.jpeg', 'pattern': [4, 4, 4, 3]}, // 15 digit
    {'name': 'Bank Tabungan Negara (BTN)', 'icon': null, 'color': Colors.blue, 'logo': 'assets/images/btn_logo.jpeg', 'pattern': [4, 4, 4, 3]}, // 15 digit
    {'name': 'GoPay', 'icon': null, 'color': Colors.lightBlue, 'logo': 'assets/images/gopay_logo.jpeg', 'pattern': [4, 4, 4]}, // 12 digit
    {'name': 'Dana', 'icon': null, 'color': Colors.blueAccent, 'logo': 'assets/images/dana_logo.jpeg', 'pattern': [4, 4, 4]}, // 12 digit
  ];

  // Fungsi untuk memformat nomor rekening berdasarkan bank yang dipilih
  void _onNomorRekeningChanged(String value) {
    if (selectedBank == null) return;
    
    // Dapatkan bank yang dipilih
    var selectedBankPattern = banks.firstWhere((bank) => bank['name'] == selectedBank)['pattern'];

    // Menghapus semua karakter selain angka
    String newValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Format nomor rekening berdasarkan pola
    String formattedValue = '';
    int startIndex = 0;
    for (int length in selectedBankPattern) {
      if (startIndex + length <= newValue.length) {
        formattedValue += newValue.substring(startIndex, startIndex + length);
        if (startIndex + length != newValue.length) {
          formattedValue += '-'; // Tambahkan strip setelah setiap blok angka
        }
      } else {
        formattedValue += newValue.substring(startIndex);
        break;
      }
      startIndex += length;
    }

    // Set text di controller dan jaga posisi kursor
    setState(() {
      _nomorRekeningController.text = formattedValue;
      _nomorRekeningController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nomorRekeningController.text.length),
      );
    });
  }

  // Fungsi untuk memformat nominal penarikan
  void _onNominalPenarikanChanged(String value) {
    String newValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _nominalPenarikanController.text = 'Rp. ' + _formatCurrency.format(int.parse(newValue.isEmpty ? '0' : newValue));
      _nominalPenarikanController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nominalPenarikanController.text.length),
      );
    });
  }

  // Fungsi untuk menampilkan dialog peringatan jika form tidak lengkap
  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Form Tidak Lengkap"),
          content: Text("Silakan lengkapi semua form sebelum menarik saldo."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog peringatan
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _tarikSaldo() async {
    // Validasi form terlebih dahulu
    if (_namaPenerimaController.text.isEmpty || selectedBank == null || _nomorRekeningController.text.isEmpty || _nominalPenarikanController.text == 'Rp. ') {
      _showWarningDialog(); // Menampilkan peringatan jika form belum lengkap
      return;
    }

    setState(() {
      _isLoading = true; // Mulai loading
    });

    // Simulasikan proses penarikan saldo (misalnya 2 detik)
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false; // Hentikan loading
    });

    // Ambil nominal penarikan tanpa "Rp." dan format ulang
    String nominalPenarikan = _nominalPenarikanController.text.replaceAll('Rp. ', '').replaceAll('.', '');

    // Simpan data ke Firestore
    await FirebaseFirestore.instance.collection('withdrawl').add({
      'idStore': 'your_store_id',  // Gantilah dengan ID toko dari pengguna saat ini
      'jumlah_penarikan': int.parse(nominalPenarikan),
      'nama_penerima': _namaPenerimaController.text,
      'nama_provider_pembayaran': selectedBank,
      'nomor_account': _nomorRekeningController.text,
      'status': 'pending',
      'tanggal': DateTime.now().toIso8601String(),
    });

    // Tampilkan pop-up berhasil
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan klik di luar pop-up
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50), // Icon sukses
              SizedBox(height: 20),
              Text("Penarikan Berhasil!", style: TextStyle(fontSize: 18)),
            ],
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog pop-up
                Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
              },
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
        title: Text('Tarik Saldo'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              // Total Pendapatan
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Rp. 0', // Set saldo awal
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Nama Penerima TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7), // Transparent background
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: TextField(
                  controller: _namaPenerimaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Penerima',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Dropdown for bank selection with bank logos
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedBank,
                  hint: Text('Pilih Bank / E-Wallet'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: banks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank['name'],
                      child: Row(
                        children: [
                          // Jika ada logo gambar bank, gunakan Image.asset, jika tidak gunakan ikon default
                          bank['logo'] != null
                              ? Image.asset(bank['logo'], width: 30, height: 30) // Menampilkan gambar logo bank
                              : Icon(bank['icon'], color: bank['color']),
                          SizedBox(width: 10),
                          Text(bank['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBank = value;
                      _nomorRekeningController.clear(); // Reset nomor rekening saat bank diubah
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              // Nomor Rekening TextField dengan Strip Otomatis
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nomorRekeningController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nomor Rekening / Akun',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: _onNomorRekeningChanged, // Panggil fungsi untuk memformat nomor rekening
                ),
              ),
              SizedBox(height: 20),
              // Nominal Penarikan TextField dengan Format Rp.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nominalPenarikanController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Penarikan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: _onNominalPenarikanChanged, // Fungsi untuk format nominal penarikan
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // Button Tarik Saldo
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _tarikSaldo, // Jika loading, disable tombol
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white) // Menampilkan loading saat ditekan
                : Text('Tarik Saldo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF62E703), // Custom green color for button
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
