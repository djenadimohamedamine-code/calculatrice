import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1C1C1E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            final canGoBack = await _controller.canGoBack();
            final canGoForward = await _controller.canGoForward();
            if (mounted) {
              setState(() {
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de navigation du navigateur
        Container(
          color: const Color(0xFF2C2C2E),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                color: _canGoBack ? Colors.white : Colors.grey.shade700,
                onPressed: _canGoBack ? () => _controller.goBack() : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                color: _canGoForward ? Colors.white : Colors.grey.shade700,
                onPressed: _canGoForward ? () => _controller.goForward() : null,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                color: Colors.white,
                onPressed: () => _controller.reload(),
              ),
              IconButton(
                icon: const Icon(Icons.home, size: 22),
                color: Colors.white,
                onPressed: () => _controller.loadRequest(Uri.parse('https://www.google.com')),
              ),
            ],
          ),
        ),
        // Le navigateur en lui-même
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
