import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/pack_providers.dart';

/// Settings screen with pack management options.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final packVersion = ref.watch(packVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pack info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content Pack',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  packVersion.when(
                    data: (version) => Text(
                      version != null
                          ? 'Installed: v$version'
                          : 'No pack installed',
                    ),
                    loading: () => const Text('Checking...'),
                    error: (_, __) => const Text('Error checking pack'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status message
          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusMessage!),
            ),
            const SizedBox(height: 16),
          ],

          // Update button
          FilledButton.icon(
            onPressed: _isUpdating ? null : _updatePack,
            icon: _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.update),
            label: Text(_isUpdating ? 'Updating...' : 'Update Pack'),
          ),
          const SizedBox(height: 8),

          // Delete button
          OutlinedButton.icon(
            onPressed: _isDeleting ? null : _deletePack,
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(_isDeleting ? 'Deleting...' : 'Delete Pack (Reset)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePack() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = 'Downloading latest pack...';
    });

    try {
      final downloadManager = ref.read(packDownloadProvider);
      await downloadManager.downloadAndInstall(
        onProgress: (received, total) {
          if (total > 0) {
            final percent = ((received / total) * 100).toStringAsFixed(0);
            setState(() {
              _statusMessage = 'Downloading: $percent%';
            });
          }
        },
      );

      // Refresh providers
      ref.invalidate(hasPackProvider);
      ref.invalidate(manifestProvider);
      ref.invalidate(packVersionProvider);

      setState(() {
        _statusMessage = 'Pack updated successfully!';
        _isUpdating = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Update failed: $e';
        _isUpdating = false;
      });
    }
  }

  Future<void> _deletePack() async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pack?'),
        content: const Text(
          'This will remove all downloaded content. You will need to download again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _statusMessage = 'Deleting pack...';
    });

    try {
      final storage = ref.read(packStorageProvider);
      final currentDir = await storage.getCurrentPackDir();

      if (await currentDir.exists()) {
        await currentDir.delete(recursive: true);
      }

      // Clean up old and new too
      await storage.cleanup();

      // Refresh providers
      ref.invalidate(hasPackProvider);
      ref.invalidate(manifestProvider);
      ref.invalidate(packVersionProvider);

      setState(() {
        _statusMessage = 'Pack deleted. Redirecting...';
        _isDeleting = false;
      });

      // Navigate back to gate screen
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Delete failed: $e';
        _isDeleting = false;
      });
    }
  }
}
