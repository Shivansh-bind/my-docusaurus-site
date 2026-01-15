import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/index_models.dart';
import '../../../../core/providers/pack_providers.dart';

/// LibraryScreen - Main navigation screen using sidebarTree
///
/// Uses the new v2.1 manifest format:
/// - sidebarTree: minimal sidebar (Semester → Subject → Essentials)
/// - Index pages open in ReaderScreen where users can navigate deeper
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
          if (packVersion != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'v$packVersion',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) {
          if (manifest == null) {
            return _buildNoPack(context);
          }
          return _buildNavigation(context, manifest);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading content',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPack(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No content pack installed'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.download),
            label: const Text('Get Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, ContentManifest manifest) {
    // Automation Level 2: Use tree with hubDocId support
    if (manifest.tree.isNotEmpty) {
      return _buildTree(context, manifest.tree, manifest);
    } else if (manifest.sidebarTree.isNotEmpty) {
      // Fallback to sidebarTree if no tree
      return _buildSidebarTree(context, manifest.sidebarTree, manifest);
    } else {
      // Last resort: build from docs map
      return _buildFromDocs(context, manifest);
    }
  }

  /// Build navigation from tree with hubDocId support
  Widget _buildTree(
    BuildContext context,
    List<TreeNode> nodes,
    ContentManifest manifest,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _buildTreeNode(context, nodes[index], manifest, 0);
      },
    );
  }

  Widget _buildTreeNode(
    BuildContext context,
    TreeNode node,
    ContentManifest manifest,
    int depth,
  ) {
    final hasChildren = node.items.isNotEmpty;
    final hasHubDocId = node.hubDocId != null;
    final hasDocId = node.docId != null;
    IconData icon = _getNodeIcon(node.title);

    // Parent node with hubDocId: tap opens hub, can also expand children
    if (hasChildren && hasHubDocId) {
      return ExpansionTile(
        leading: GestureDetector(
          onTap: () => _openDoc(context, node.hubDocId!),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: GestureDetector(
          onTap: () => _openDoc(context, node.hubDocId!),
          child: Text(
            node.title,
            style: TextStyle(
              fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(Icons.expand_more),
        initiallyExpanded:
            false, // Don't expand by default, user should tap to open hub
        children: node.items
            .map((child) => _buildTreeNode(context, child, manifest, depth + 1))
            .toList(),
      );
    }
    // Parent node without hubDocId: just expand
    else if (hasChildren) {
      return ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          node.title,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        initiallyExpanded: depth == 0,
        children: node.items
            .map((child) => _buildTreeNode(context, child, manifest, depth + 1))
            .toList(),
      );
    }
    // Leaf node with docId
    else if (hasDocId) {
      return ListTile(
        leading: Icon(icon, size: 20),
        title: Text(node.title),
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => _openDoc(context, node.docId!),
      );
    }
    // Fallback: just display
    else {
      return ListTile(
        leading: Icon(icon),
        title: Text(node.title),
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
      );
    }
  }

  /// Build navigation from new sidebarTree (v2.1)
  Widget _buildSidebarTree(
    BuildContext context,
    List<SidebarNode> nodes,
    ContentManifest manifest,
  ) {
    if (nodes.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _buildSidebarNode(context, nodes[index], manifest, 0);
      },
    );
  }

  Widget _buildSidebarNode(
    BuildContext context,
    SidebarNode node,
    ContentManifest manifest,
    int depth,
  ) {
    final hasChildren = node.items.isNotEmpty;
    final hasDocId = node.docId != null;

    // Get icon based on title or type
    IconData icon = _getNodeIcon(node.title);

    if (hasChildren) {
      // Branch with children - use ExpansionTile
      return ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          node.title,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        initiallyExpanded: depth == 0, // Expand semesters by default
        children: node.items
            .map((child) =>
                _buildSidebarNode(context, child, manifest, depth + 1))
            .toList(),
      );
    } else if (hasDocId) {
      // Leaf node - open doc
      final doc = manifest.getDoc(node.docId!);
      return ListTile(
        leading: Icon(icon, size: 20),
        title: Text(node.title),
        subtitle: doc != null
            ? Text(doc.category, style: const TextStyle(fontSize: 12))
            : null,
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
        onTap: () => _openDoc(context, node.docId!),
      );
    } else {
      // Empty node (shouldn't happen, but handle gracefully)
      return ListTile(
        leading: Icon(icon),
        title: Text(node.title),
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
      );
    }
  }

  /// Fallback: Build from docs map
  Widget _buildFromDocs(BuildContext context, ContentManifest manifest) {
    final docs = manifest.docs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final entry = docs[index];
        return ListTile(
          title: Text(entry.value.title),
          subtitle: Text(entry.key),
          onTap: () => _openDoc(context, entry.key),
        );
      },
    );
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
    if (lower.contains('math') || lower.contains('discrete'))
      return Icons.calculate;
    if (lower.contains('english')) return Icons.language;
    if (lower.contains('dld') || lower.contains('digital')) return Icons.memory;
    if (lower.contains('cfoa') || lower.contains('computer'))
      return Icons.computer;
    return Icons.article;
  }

  void _openDoc(BuildContext context, String docId) {
    context.push('/reader', extra: {'docId': docId});
  }
}
