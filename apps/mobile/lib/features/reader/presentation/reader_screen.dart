import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/storage/pack_storage_manager.dart';

/// Screen that displays document content using a WebView.
///
/// Supports two modes:
/// 1. Local pack mode (preferred): Loads HTML from local packs/current/docs/
/// 2. URL mode (fallback): Loads from a provided URL
///
/// Navigation handling:
/// - `app://doc/<docId>` links navigate within the app
/// - `file://` links are allowed (local assets)
/// - External links open in browser via url_launcher
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final WebViewController _controller;
  final PackStorageManager _packStorage = PackStorageManager();

  bool _isLoading = true;
  int _progress = 0;
  bool _hasError = false;
  String? _errorMessage;

  String? _currentDocId;
  Uri? _currentUri;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
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
          onNavigationRequest: _handleNavigationRequest,
        ),
      );
  }

  /// Handle navigation requests from the WebView
  Future<NavigationDecision> _handleNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) {
      return NavigationDecision.navigate;
    }

    // Fix #5: Handle app://doc/<docId> AND app://doc?id=<docId> links
    if (uri.scheme == 'app' && uri.host == 'doc') {
      String? docId;

      // Try path format: app://doc/<docId>
      if (uri.pathSegments.isNotEmpty) {
        docId = uri.pathSegments[0];
      }

      // Try query format: app://doc?id=<docId>
      if ((docId == null || docId.isEmpty) &&
          uri.queryParameters.containsKey('id')) {
        docId = uri.queryParameters['id'];
      }

      if (docId != null && docId.isNotEmpty) {
        // Navigate to the new doc within the app
        await _loadDoc(docId);
        return NavigationDecision.prevent;
      }
    }

    // Handle file:// links (local assets) - allow
    if (uri.scheme == 'file') {
      return NavigationDecision.navigate;
    }

    // Handle http/https links
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      // Open in external browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }

    // Handle mailto:, tel:, etc.
    if (uri.scheme == 'mailto' || uri.scheme == 'tel') {
      await launchUrl(uri);
      return NavigationDecision.prevent;
    }

    // Allow other navigation
    return NavigationDecision.navigate;
  }

  /// Load a document by its docId
  Future<void> _loadDoc(String docId) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentDocId = docId;
    });

    try {
      final docUri = await _packStorage.getDocUri(docId);
      if (docUri != null) {
        _currentUri = docUri;
        await _controller.loadRequest(docUri);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Document not found: $docId';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load document: $e';
        _isLoading = false;
      });
    }
  }

  /// Load a document by URL (legacy/fallback mode)
  Future<void> _loadUrl(String url) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(url);
      _currentUri = uri;
      await _controller.loadRequest(uri);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load URL: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;

    final data = (extra is Map) ? extra : <String, dynamic>{};
    final docId = data['docId']?.toString();
    final url = data['url']?.toString();
    final title = data['title']?.toString() ?? 'Reader';

    // Load content on first build
    if (_currentUri == null && !_hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (docId != null && docId.isNotEmpty) {
          _loadDoc(docId);
        } else if (url != null && url.isNotEmpty) {
          _loadUrl(url);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'No document or URL provided';
          });
        }
      });
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
              tooltip: 'Reload',
            ),
            if (_currentUri != null &&
                (_currentUri!.scheme == 'http' ||
                    _currentUri!.scheme == 'https'))
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: () async {
                  if (_currentUri != null) {
                    await launchUrl(
                      _currentUri!,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                tooltip: 'Open in browser',
              ),
          ],
        ),
        body: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(value: _progress / 100),
              ),
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Document',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentDocId != null) {
                            _loadDoc(_currentDocId!);
                          } else if (_currentUri != null) {
                            _controller.reload();
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
