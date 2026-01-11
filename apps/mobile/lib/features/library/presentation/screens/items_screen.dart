import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/index_models.dart';
import '../library_providers.dart';
import 'package:referencelibrary/core/constants/app_constants.dart';
import 'package:referencelibrary/core/utils/url_utils.dart';

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({
    super.key,
    required this.semesterName,
    required this.subjectName,
    required this.sectionName,
  });

  final String semesterName;
  final String subjectName;
  final String sectionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIndex = ref.watch(appIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(sectionName)),
      body: asyncIndex.when(
        data: (index) {
          final semester =
              index.semesters.firstWhere((s) => s.name == semesterName);
          final subject =
              semester.subjects.firstWhere((s) => s.name == subjectName);
          final section =
              subject.sections.firstWhere((s) => s.name == sectionName);

          final items = section.items;
          if (items.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final item = items[i];
              return _ItemTile(item: item);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    // build final absolute URL for the item using UrlUtils.normalizeUrl
    final fixedUrl = UrlUtils.normalizeUrl(
      item.url,
      siteOrigin: AppConstants.siteOrigin,
    );

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      title: Text(item.title),
      subtitle: Text(item.type),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => context.go(
        '/reader',
        extra: {'url': fixedUrl, 'title': item.title},
      ),
    );
  }
}
