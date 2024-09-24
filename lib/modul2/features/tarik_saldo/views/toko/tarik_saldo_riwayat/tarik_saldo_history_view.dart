import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import '/modul2/features/tarik_saldo/views/toko/tarik_saldo_riwayat/tarik_saldo_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/modul2/features/tarik_saldo/providers/withdrawal_provider.dart';

class TarikSaldoHistoryView extends StatefulWidget {
  const TarikSaldoHistoryView({super.key});

  @override
  TarikSaldoHistoryViewState createState() => TarikSaldoHistoryViewState();
}

class TarikSaldoHistoryViewState extends State<TarikSaldoHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WithdrawalProvider>(context, listen: false)
          .fetchWithdrawalsForCurrentUser();
    });
  }

  // Fungsi untuk refresh data saat swipe down
  Future<void> _refreshData() async {
    await Provider.of<WithdrawalProvider>(context, listen: false)
        .fetchWithdrawalsForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Riwayat Penarikan',
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
      body: Stack(
        children: [
          Consumer<WithdrawalProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Text('Error: ${provider.error}'),
                );
              }

              if (provider.withdrawals.isEmpty) {
                return const Center(
                    child: Text('Tidak ada riwayat penarikan.'));
              }

              final withdrawalsByMonth =
                  _groupWithdrawalsByMonth(provider.withdrawals);

              // Tambahkan RefreshIndicator di sini
              return RefreshIndicator(
                onRefresh: _refreshData, // Fungsi untuk refresh data
                child: ListView.builder(
                  itemCount: withdrawalsByMonth.length,
                  itemBuilder: (context, index) {
                    final month = withdrawalsByMonth.keys.elementAt(index);
                    final withdrawals = withdrawalsByMonth[month]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthSection(month),
                        ...withdrawals
                            .map((withdrawal) =>
                                _buildWithdrawalCard(withdrawal))
                            .toList(),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        month,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Nunito', // Menggunakan font NunitoExtraBold
        ),
      ),
    );
  }

  // Card-based UI for each withdrawal
  Widget _buildWithdrawalCard(TarikSaldoModel withdrawal) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detail page when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TarikSaldoDetailView(withdrawal: withdrawal),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _getProviderIcon(withdrawal.provider),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(withdrawal.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,##0', 'id_ID').format(withdrawal.nominal)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito', // Font NunitoExtraBold
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(withdrawal.tanggal),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Nunito', // Font NunitoExtraBold
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  _getStatusIcon(withdrawal.status),
                  color: _getIconColor(withdrawal.status),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Badge to visually represent the status
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'success':
        badgeColor = Colors.green;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        break;
      case 'cancel':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito', // Font NunitoExtraBold
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan teks status
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'cancel':
        return 'Penarikan Dibatalkan';
      case 'success':
        return 'Penarikan Berhasil';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  // Fungsi untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'cancel':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk mendapatkan ikon berdasarkan status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancel':
        return Icons.cancel;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Fungsi untuk mendapatkan warna ikon
  Color _getIconColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk mendapatkan ikon provider dengan ukuran lebih kecil
  Widget _getProviderIcon(String provider) {
  String providerLower = provider.toLowerCase();

  if (providerLower.contains('bca') ||
      providerLower.contains('bank central asia')) {
    return Image.asset('assets/images/bca_logo.jpeg',
        width: 30, height: 30); // Ikon BCA
  } else if (providerLower.contains('mandiri')) {
    return Image.asset('assets/images/mandiri_logo.jpeg',
        width: 30, height: 30); // Ikon Mandiri
  } else if (providerLower.contains('bni') ||
      providerLower.contains('bank negara indonesia')) {
    return Image.asset('assets/images/bni_logo.jpeg',
        width: 30, height: 30); // Ikon BNI
  } else if (providerLower.contains('bri') ||
      providerLower.contains('bank rakyat indonesia')) {
    return Image.asset('assets/images/bri_logo.jpeg',
        width: 30, height: 30); // Ikon BRI
  } else if (providerLower.contains('btn') ||
      providerLower.contains('bank tabungan negara')) {
    return Image.asset('assets/images/btn_logo.jpeg',
        width: 30, height: 30); // Ikon BTN
  } else if (providerLower.contains('gopay')) {
    return Image.asset('assets/images/gopay_logo.jpeg',
        width: 30, height: 30); // Ikon GoPay
  } else if (providerLower.contains('dana')) {
    return Image.asset('assets/images/dana_logo.jpeg',
        width: 30, height: 30); // Ikon DANA
  } else {
    return const Icon(Icons.account_balance_wallet,
        size: 30); // Ikon default jika tidak ditemukan
  }
}


  Map<String, List<TarikSaldoModel>> _groupWithdrawalsByMonth(
      List<TarikSaldoModel> withdrawals) {
    Map<String, List<TarikSaldoModel>> grouped = {};

    for (var withdrawal in withdrawals) {
      final monthYear =
          DateFormat('MMMM yyyy', 'id_ID').format(withdrawal.tanggal);
      if (grouped.containsKey(monthYear)) {
        grouped[monthYear]!.add(withdrawal);
      } else {
        grouped[monthYear] = [withdrawal];
      }
    }

    return grouped;
  }
}
