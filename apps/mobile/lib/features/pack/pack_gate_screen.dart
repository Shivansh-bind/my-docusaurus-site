import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/pack_providers.dart';

/// First screen shown on app launch.
///
/// Fix #1: Uses ConsumerStatefulWidget with initState() for navigation,
/// NOT auto-navigation in build() which causes loops.
class PackGateScreen extends ConsumerStatefulWidget {
  const PackGateScreen({super.key});

  @override
  ConsumerState<PackGateScreen> createState() => _PackGateScreenState();
}

class _PackGateScreenState extends ConsumerState<PackGateScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _hasCheckedPack = false;

  @override
  void initState() {
    super.initState();
    // Fix #1: Check pack in initState with microtask, not in build()
    Future.microtask(_checkPackAndNavigate);
  }

  Future<void> _checkPackAndNavigate() async {
    if (!mounted) return;

    try {
      final storage = ref.read(packStorageProvider);
      final hasPack = await storage.hasValidPack();

      if (!mounted) return;

      if (hasPack) {
        // Has valid pack - navigate to library
        context.go('/library');
      } else {
        // No pack - show download UI
        setState(() {
          _hasCheckedPack = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCheckedPack = true;
        _errorMessage = 'Error checking pack: $e';
      });
    }
  }

  Future<void> _downloadPack() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final downloadManager = ref.read(packDownloadProvider);

      await downloadManager.downloadAndInstall(
        onProgress: (received, total) {
          if (!mounted) return;
          if (total > 0) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (!mounted) return;

      // Invalidate the hasPack provider to refresh state
      ref.invalidate(hasPackProvider);
      ref.invalidate(manifestProvider);

      // Navigate to library
      context.go('/library');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Still checking pack
    if (!_hasCheckedPack) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking for study assets...'),
        ],
      );
    }

    // Downloading
    if (_isDownloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.download, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Downloading Study Assets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _downloadProgress),
          const SizedBox(height: 8),
          Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
        ],
      );
    }

    // Show download button
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.library_books, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'Reference Library',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your offline study companion',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: _downloadPack,
          icon: const Icon(Icons.download),
          label: const Text('Get Study Assets'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }
}
