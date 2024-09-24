import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import '/modul2/features/tarik_saldo/repositories/pembeli/withdrawal_pembeli_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawalPembeliProvider with ChangeNotifier {
  final WithdrawalPembeliRepository _repository = WithdrawalPembeliRepository();
  List<TarikSaldoModel> _withdrawals = [];
  bool _isLoading = false;
  String? _error;

  List<TarikSaldoModel> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> fetchWithdrawalsForCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Fetching withdrawals for user with UID: ${user.uid}');
      // Mengambil penarikan berdasarkan UID pengguna
      _withdrawals = await _repository.fetchWithdrawalsByUserId(user.uid);
      print('Number of withdrawals fetched: ${_withdrawals.length}');
    } catch (e) {
      print('Error fetching withdrawals: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
