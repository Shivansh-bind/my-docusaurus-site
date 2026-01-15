import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/index_models.dart';
import '../../../../core/providers/pack_providers.dart';

/// LibraryScreen - Website-style navigation with WebView + Drawer
///
/// Entry point: Loads homepage.html
/// Navigation: Hamburger sidebar with doc tree
/// Back: Web history navigation
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  WebViewController? _webController;
  bool _canGoBack = false;
  String _currentTitle = 'Reference Library';
  bool _initialized = false;
  String? _packPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initWebView();
    }
  }

  Future<void> _initWebView() async {
    // Wait for pack path to be available
    final packPath = await ref.read(packPathProvider.future);
    if (packPath == null) return;
    _packPath = packPath;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _updateBackButton();
          },
          onPageFinished: (url) {
            _updateBackButton();
            _updateTitle();
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Handle app://doc/ links
            if (url.startsWith('app://doc/')) {
              final docId = url.replaceFirst('app://doc/', '');
              _loadDoc(docId);
              return NavigationDecision.prevent;
            }

            // Allow file:// URLs (local content)
            if (url.startsWith('file://')) {
              return NavigationDecision.navigate;
            }

            // Block external URLs
            return NavigationDecision.prevent;
          },
        ),
      );

    setState(() {
      _webController = controller;
    });

    // Load homepage
    _loadDoc('homepage');
  }

  void _loadDoc(String docId) {
    if (_packPath == null || _webController == null) return;

    final filePath = '$_packPath/docs/$docId.html';
    final file = File(filePath);

    if (file.existsSync()) {
      // Use loadFile instead of loadRequest for local file access on Android
      _webController!.loadFile(filePath);
    } else {
      // Fallback: show error
      debugPrint('File not found: $filePath');
      _webController!.loadHtmlString('''
        <html>
        <head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
        <body style="font-family: sans-serif; padding: 40px; text-align: center;">
          <h2>Document not found</h2>
          <p>$docId</p>
        </body>
        </html>
      ''');
    }
  }

  Future<void> _updateBackButton() async {
    if (_webController == null) return;
    final canGoBack = await _webController!.canGoBack();
    if (mounted && canGoBack != _canGoBack) {
      setState(() {
        _canGoBack = canGoBack;
      });
    }
  }

  Future<void> _updateTitle() async {
    if (_webController == null) return;
    final title = await _webController!.getTitle();
    if (mounted && title != null && title.isNotEmpty) {
      setState(() {
        _currentTitle = title;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_webController != null && await _webController!.canGoBack()) {
      _webController!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(manifestProvider);
    final packVersion = ref.watch(packVersionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentTitle,
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
          actions: [
            if (_canGoBack)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _webController?.goBack(),
                tooltip: 'Back',
              ),
            if (packVersion != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v$packVersion',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _loadDoc('homepage'),
              tooltip: 'Home',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        drawer: manifestAsync.when(
          data: (manifest) => manifest != null
              ? _buildDrawer(context, manifest)
              : const Drawer(child: Center(child: Text('No content'))),
          loading: () => const Drawer(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Drawer(
            child: Center(child: Text('Error: $e')),
          ),
        ),
        body: _webController == null
            ? const Center(child: CircularProgressIndicator())
            : WebViewWidget(controller: _webController!),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ContentManifest manifest) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Reference Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (ref.watch(packVersionProvider) != null)
                    Text(
                      'v${ref.watch(packVersionProvider)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Home button
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _loadDoc('homepage');
              },
            ),
            const Divider(height: 1),

            // Doc tree
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _buildTreeItems(context, manifest.tree),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTreeItems(BuildContext context, List<TreeNode> nodes) {
    return nodes.map((node) => _buildTreeNode(context, node, 0)).toList();
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node, int depth) {
    final hasChildren = node.items.isNotEmpty;
    final docId = node.openDocId; // hubDocId for parents, docId for leaves

    if (hasChildren) {
      return ExpansionTile(
        leading: Icon(_getNodeIcon(node.title)),
        title: Text(
          node.title,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tilePadding: EdgeInsets.only(left: 16 + (depth * 8), right: 16),
        children: node.items
            .map((child) => _buildTreeNode(context, child, depth + 1))
            .toList(),
      );
    } else if (docId != null) {
      return ListTile(
        leading: Icon(_getNodeIcon(node.title), size: 20),
        title: Text(node.title),
        contentPadding: EdgeInsets.only(left: 16 + (depth * 12), right: 16),
        onTap: () {
          Navigator.pop(context); // Close drawer
          _loadDoc(docId);
        },
      );
    } else {
      return ListTile(
        leading: Icon(_getNodeIcon(node.title)),
        title: Text(node.title),
        contentPadding: EdgeInsets.only(left: 16 + (depth * 12), right: 16),
      );
    }
  }

  IconData _getNodeIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('semester')) return Icons.school;
    if (lower.contains('handout')) return Icons.description;
    if (lower.contains('notes')) return Icons.note;
    if (lower.contains('pyq')) return Icons.quiz;
    if (lower.contains('assignment')) return Icons.assignment;
    if (lower.contains('project')) return Icons.folder_special;
    if (lower.contains('programming')) return Icons.code;
    if (lower.contains('math') || lower.contains('discrete')) {
      return Icons.calculate;
    }
    if (lower.contains('english')) return Icons.language;
    if (lower.contains('dld') || lower.contains('digital')) return Icons.memory;
    if (lower.contains('cfoa') || lower.contains('computer')) {
      return Icons.computer;
    }
    return Icons.article;
  }
}
