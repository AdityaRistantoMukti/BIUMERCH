import 'package:flutter/material.dart';

class StatusHelper {
  static String getStatusText(String status) {
    switch (status) {
      case "completed":
        return "Selesai";
      case "cancel":
        return "Pembayaran Gagal";
      case "pending":
        return "Belum Bayar";
      case "waiting-store-confirmation":
        return "Menunggu Konfirmasi Toko";
      case "is-preparing":
        return "Pesanan Sedang Dipersiapkan";
      case "in-delivery":
        return "Dalam Pengiriman";
         case "canceled-by-user":
        return "Dibatalkan";
      case "completed-delivery":
        return "Pesanan Terkirim";
      default:
        return "Status Tidak Diketahui";
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case "completed":
        return Colors.green[100]!;
      case "cancel":
        return Colors.red[100]!;
      case "pending":
        return Colors.orange[100]!;
      case "waiting-store-confirmation":
        return Colors.blue[100]!;
      case "is-preparing":
        return Colors.orange[100]!;
      case "in-delivery":
        return Colors.blue[100]!;
          case "canceled-by-user":
        return Colors.red[100]!;
      case "completed-delivery":
        return Colors.blue[100]!;
      default:
        return Colors.grey[300]!;
    }
  }

  static Color getStatusTextColor(String status) {
    switch (status) {
      case "completed":
        return Colors.green;
      case "cancel":
        return Colors.red;
      case "pending":
        return Colors.orange;
      case "waiting-store-confirmation":
        return Colors.blue;
      case "is-preparing":
        return Colors.orange;
        case "canceled-by-user":
        return Colors.red;
      case "in-delivery":
        return Colors.blue;
      case "completed-delivery":
        return Colors.blue;
      default:
        return Colors.black;
    }
  }
}

