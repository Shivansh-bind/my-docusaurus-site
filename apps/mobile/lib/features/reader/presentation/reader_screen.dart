import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:referencelibrary/core/constants/app_constants.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;
  int _progress = 0;
  bool _hasError = false;
  String? _errorMessage;

  Uri? _currentUri; // current loaded page

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _progress = 0;
            });
            _currentUri = Uri.tryParse(url);
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _hasError = false;
              _progress = 100;
            });
            _currentUri = Uri.tryParse(url);
          },
          onWebResourceError: (err) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = err.description;
            });
          },
          onNavigationRequest: (req) async {
            final resolved = _resolveUrl(req.url);

            // if external host => open browser, block webview nav
            final siteHost = Uri.parse(AppConstants.siteOrigin).host;
            if (resolved.host.isNotEmpty && resolved.host != siteHost) {
              await launchUrl(resolved, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }

            // Detection: if we modified the URL (e.g. fixed %2520) OR it was relative
            // then we MUST force-load the clean absolute URL.
            if (resolved.toString() != req.url) {
              _controller.loadRequest(resolved);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Uri _resolveUrl(String raw) {
    // Robustness: fix accidental double-encoding from source
    if (raw.contains('%2520')) {
      raw = raw.replaceAll('%2520', '%20');
    }

    final uri = Uri.parse(raw);

    // Already absolute
    if (uri.hasScheme) return uri;

    final base = _currentUri ?? Uri.parse(AppConstants.siteOrigin);

    // root-relative
    if (raw.startsWith('/')) {
      return Uri.parse(
        AppConstants.siteOrigin,
      ).replace(path: raw, query: uri.query, fragment: uri.fragment);
    }

    // relative to current page
    return base.resolveUri(uri);
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;

    final data = (extra is Map) ? extra : <String, dynamic>{};
    final initialUrl = (data['url'] ?? AppConstants.siteOrigin).toString();
    final title = (data['title'] ?? 'Reader').toString();

    // load only once
    if (_currentUri == null) {
      _currentUri = Uri.tryParse(initialUrl);
      _controller.loadRequest(_currentUri!);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final canGoBack = await _controller.canGoBack();
        if (!context.mounted) return;

        if (canGoBack) {
          await _controller.goBack();
          return;
        }

        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                final u = _currentUri ?? Uri.parse(initialUrl);
                await launchUrl(u, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) LinearProgressIndicator(value: _progress / 100),
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${_errorMessage ?? 'Unknown'}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
