import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderBloc extends ChangeNotifier {
  final DocumentSnapshot order;
  final List<DocumentSnapshot> filteredItems;
  String? productFilterStatus;

  DateTime startTime = DateTime.now();
  String? storeName;
  bool isStoreLoaded = false;
  Timer? _timer;

  OrderBloc({
    required this.order,
    required this.filteredItems,
    this.productFilterStatus,
  }) {
    _loadStartTime();
    _loadStoreName();
    _startTimer();
  }

  // Load store name from Firebase
  Future<void> _loadStoreName() async {
    if (!isStoreLoaded) {
      final itemDoc = filteredItems.isNotEmpty ? filteredItems[0] : null;
      if (itemDoc != null) {
        String storeId = itemDoc.id;
        DocumentSnapshot storeSnapshot =
            await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
        if (storeSnapshot.exists) {
          final storeData = storeSnapshot.data() as Map<String, dynamic>?;
          storeName = storeData?['storeName'] ?? 'Unknown Store';
          isStoreLoaded = true;
          notifyListeners();
        } else {
          storeName = 'Toko Tidak Ditemukan';
          isStoreLoaded = true;
          notifyListeners();
        }
      }
    }
  }

  // Load start time from SharedPreferences
  Future<void> _loadStartTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedStartTime = prefs.getString('startTime_${order.id}');
    if (savedStartTime != null) {
      startTime = DateTime.parse(savedStartTime);
    } else {
      await prefs.setString('startTime_${order.id}', startTime.toIso8601String());
    }
    notifyListeners();
  }

  // Timer to periodically update UI
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
  }

  // Dispose resources
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
