import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecaptchaScreen extends StatefulWidget {
  final Function(String) onVerified;

  const RecaptchaScreen({Key? key, required this.onVerified}) : super(key: key);

  @override
  _RecaptchaScreenState createState() => _RecaptchaScreenState();
}

class _RecaptchaScreenState extends State<RecaptchaScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            _controller.clearCache(); // Bersihkan cache sebelum memuat halaman
            // Check if the URL contains 'success' to confirm captcha success
            if (url.contains('success')) {
              await _setCaptchaVerified(true); // Set isCaptchaVerified to true
              widget.onVerified('success');
              Navigator.pop(context, 'success'); // Return to previous screen
            } else if (url.contains('failed')) {
              await _setCaptchaVerified(false); // Set isCaptchaVerified to false
              widget.onVerified('failed');
              Navigator.pop(context, 'failed'); // Return to previous screen
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://adityaristantomukti.github.io/BIUMERCH/')); // Change URL accordingly
  }

  Future<void> _setCaptchaVerified(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCaptchaVerified', value); // Update isCaptchaVerified
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify reCAPTCHA'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
