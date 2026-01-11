import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:referencelibrary/core/utils/url_utils.dart';
import 'package:referencelibrary/core/constants/app_constants.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _hasLoadedUrl = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _initialUrl;
  String? _currentUrl;

  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() {
            _isLoading = false;
            _hasError = false;
            _currentUrl = url;
          }),
          onWebResourceError: (err) => setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = err.description;
          }),
          onNavigationRequest: (req) {
            // Resolve and normalize hrefs against currentUrl
            final nextUrl = UrlUtils.resolveHref(
              currentUrl: _currentUrl ?? AppConstants.siteOrigin,
              href: req.url,
              siteOrigin: AppConstants.siteOrigin,
            );

            final nextUri = Uri.parse(nextUrl);
            final siteHost = Uri.parse(AppConstants.siteOrigin).host;

            if (nextUri.host != siteHost) {
              launchUrl(Uri.parse(nextUrl),
                  mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _maybeLoadInitialUrl() {
    if (_hasLoadedUrl) return;

    final stateExtra = GoRouterState.of(context).extra;
    String? rawUrl;
    if (stateExtra is Map && stateExtra['url'] is String) {
      rawUrl = stateExtra['url'] as String;
    }

    if (rawUrl == null || rawUrl.isEmpty) return;

    _hasLoadedUrl = true;
    final url = AppConstants.normalizeDocUrl(rawUrl);

    _initialUrl = url;
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _refresh() async {
    try {
      await _controller.reload();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (_) {}
  }

  Future<void> _retry() async {
    if (_initialUrl == null) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _progress = 0;
    });
    await _controller.loadRequest(Uri.parse(_initialUrl!));
  }

  Future<void> _safeBack() async {
    final controller = _controller;

    // Capture navigator and router to avoid using BuildContext across async gaps
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    if (await controller.canGoBack()) {
      await controller.goBack();
      return;
    }

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    _maybeLoadInitialUrl();

    final stateExtra = GoRouterState.of(context).extra;
    String? title;
    if (stateExtra is Map && stateExtra['title'] is String) {
      title = stateExtra['title'] as String;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _safeBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title ?? 'Reader'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _safeBack,
          ),
          actions: [
            IconButton(
              tooltip: 'Reload',
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Open in browser',
              onPressed: () async {
                final stateExtra = GoRouterState.of(context).extra;
                String? url;
                if (stateExtra is Map && stateExtra['url'] is String) {
                  url = stateExtra['url'] as String;
                }
                if (url == null || url.isEmpty) return;

                final uri = Uri.tryParse(url) ??
                    Uri.parse(AppConstants.siteOrigin).resolve(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 100
                ? LinearProgressIndicator(value: _progress / 100)
                : const SizedBox(height: 3),
          ),
        ),
        body: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _refresh,
          child: Stack(
            children: [
              // underlying background to avoid white flashes
              Container(color: Theme.of(context).scaffoldBackgroundColor),
              WebViewWidget(controller: _controller),

              // error UI sits above the WebView when load fails
              if (_hasError)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load page',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_errorMessage != null)
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: _retry,
                                  child: const Text('Retry'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_initialUrl == null) return;
                                    final uri = Uri.tryParse(_initialUrl!) ??
                                        Uri.parse(AppConstants.siteOrigin)
                                            .resolve(_initialUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: const Text('Open in browser'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // gentle progress indicator (not hiding webview)
              if (_isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(value: _progress / 100),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
