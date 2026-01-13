import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/pack_providers.dart';
import '../../domain/index_models.dart';

/// Manifest-driven library navigation screen.
/// Shows content tree from current pack's index.json.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(manifestProvider);
    final packVersion = ref.watch(packVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference Library'),
        actions: [
          // Pack version badge
          packVersion.when(
            data: (version) => version != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'v$version',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) {
          if (manifest == null) {
            return const Center(
              child: Text('No content pack installed'),
            );
          }
          return _buildTree(context, manifest);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading manifest: $error'),
        ),
      ),
    );
  }

  Widget _buildTree(BuildContext context, ContentManifest manifest) {
    if (manifest.tree.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: manifest.tree.length,
      itemBuilder: (context, index) {
        final node = manifest.tree[index];
        return _buildSemesterTile(context, node, manifest);
      },
    );
  }

  Widget _buildSemesterTile(
    BuildContext context,
    TreeNode semester,
    ContentManifest manifest,
  ) {
    return ExpansionTile(
      leading: const Icon(Icons.folder),
      title: Text(
        semester.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: semester.items?.map((subject) {
            return _buildSubjectTile(context, subject, manifest);
          }).toList() ??
          [],
    );
  }

  Widget _buildSubjectTile(
    BuildContext context,
    TreeNode subject,
    ContentManifest manifest,
  ) {
    // If it has items, it's a branch (subject with docs)
    if (subject.items != null && subject.items!.isNotEmpty) {
      return ExpansionTile(
        leading: const Icon(Icons.book),
        title: Text(subject.title),
        children: subject.items!.map((item) {
          return _buildDocTile(context, item, manifest);
        }).toList(),
      );
    }

    // If it has a docId, it's a leaf
    if (subject.docId != null) {
      return _buildDocLeaf(context, subject, manifest);
    }

    // Empty branch
    return ListTile(
      leading: const Icon(Icons.folder_open),
      title: Text(subject.title),
    );
  }

  Widget _buildDocTile(
    BuildContext context,
    TreeNode item,
    ContentManifest manifest,
  ) {
    if (item.docId != null) {
      return _buildDocLeaf(context, item, manifest);
    }

    // Nested branch
    if (item.items != null && item.items!.isNotEmpty) {
      return ExpansionTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(item.title),
        children: item.items!.map((child) {
          return _buildDocTile(context, child, manifest);
        }).toList(),
      );
    }

    return ListTile(title: Text(item.title));
  }

  Widget _buildDocLeaf(
    BuildContext context,
    TreeNode item,
    ContentManifest manifest,
  ) {
    final doc = item.docId != null ? manifest.getDoc(item.docId!) : null;
    final icon = _getTypeIcon(item.type ?? doc?.type);

    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(item.title),
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      onTap: () {
        if (item.docId != null) {
          context.push('/reader', extra: {'docId': item.docId});
        }
      },
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'index':
        return Icons.home;
      case 'handout':
        return Icons.description;
      case 'notes':
        return Icons.article;
      case 'pyq':
        return Icons.quiz;
      case 'assignments':
        return Icons.assignment;
      case 'intro':
        return Icons.info;
      default:
        return Icons.article_outlined;
    }
  }
}
