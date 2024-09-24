import '/modul2/features/tarik_saldo/models/tarik_saldo_model.dart';
import '/modul2/features/tarik_saldo/repositories/toko/withdrawal_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawalProvider with ChangeNotifier {
  final WithdrawalRepository _repository = WithdrawalRepository();
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
      String? idStore = await _repository.getIdStoreByOwnerId(user.uid);

      if (idStore == null) {
        throw Exception('No store found for this user');
      }

      _withdrawals = await _repository.fetchWithdrawalsByStoreId(idStore);
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
