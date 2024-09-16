import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecaptchaHandler extends StatefulWidget {
  final Function(String) onVerified;

  const RecaptchaHandler({Key? key, required this.onVerified}) : super(key: key);

  @override
  _RecaptchaScreenState createState() => _RecaptchaScreenState();
}

class _RecaptchaScreenState extends State<RecaptchaHandler> {
  late final WebViewController _controller;
  bool _isLoading = true;  // Track loading state for loader

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..clearCache()  // Clear cache before starting
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            // Check if the URL starts with the custom scheme
            if (request.url.startsWith('myapp://')) {
              if (request.url.contains('success')) {
                await _setCaptchaVerified(true);  // Set isCaptchaVerified to true
                widget.onVerified('success');
                Navigator.pop(context, 'success');
              } else if (request.url.contains('failed')) {
                await _setCaptchaVerified(false);  // Set isCaptchaVerified to false
                widget.onVerified('failed');
                Navigator.pop(context, 'failed');
              }
              return NavigationDecision.prevent;  // Prevent navigation to myapp:// links
            }
            return NavigationDecision.navigate;  // Allow other navigations
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;  // Hide loader once the page is fully loaded
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;  // Hide loader in case of error
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Failed to load page: ${error.description}"),
            ));
          },
        ),
      )
      ..loadRequest(Uri.parse('https://adityaristantomukti.github.io/BIUMERCH/'));  // Load your reCAPTCHA page
  }

  // Add the _setCaptchaVerified function
  Future<void> _setCaptchaVerified(bool isVerified) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCaptchaVerified', isVerified);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify reCAPTCHA'),
      ),
      body: Stack(
        children: [
          AbsorbPointer(  // Absorb interaction during loading
            absorbing: _isLoading,  // True when loading, false after load
            child: WebViewWidget(controller: _controller),  // The WebView widget
          ),
          if (_isLoading)  // Display a loader when the WebView is loading
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),  // Change loader color to green
              ),
            ),
        ],
      ),
    );
  }
}
