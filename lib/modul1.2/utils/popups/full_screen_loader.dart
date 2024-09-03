import '/modul1.2/common/widgets/loaders/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TFullScreenLoader {
  static void openLoadingDialog(String text) {
  BuildContext? context = Get.overlayContext ?? Get.context;
  if (context != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: TLoadingWidget(text: text),
          ),
        ),
      ),
    );
  } else {
    print('No valid context available to show dialog');
    // Tangani kasus di mana tidak ada context yang valid
  }
}


  static stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }
}
