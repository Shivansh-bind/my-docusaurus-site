import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/pack_storage_manager.dart';
import '../storage/pack_download_manager.dart';
import '../../features/library/domain/index_models.dart';

/// Provider for PackStorageManager (singleton)
/// Fix #2: Single instance shared across all providers
final packStorageProvider = Provider<PackStorageManager>((ref) {
  return PackStorageManager();
});

/// Provider for PackDownloadManager
final packDownloadProvider = Provider<PackDownloadManager>((ref) {
  final storage = ref.watch(packStorageProvider);
  return PackDownloadManager(storageManager: storage);
});

/// Provider for checking if pack exists
final hasPackProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(packStorageProvider);
  return storage.hasValidPack();
});

/// Provider for the current manifest
/// Fix #2: Depends on packStorageProvider, not creating new instance
final manifestProvider = FutureProvider<ContentManifest?>((ref) async {
  final storage = ref.watch(packStorageProvider);
  return storage.getManifest();
});

/// Provider for pack version string
final packVersionProvider = FutureProvider<String?>((ref) async {
  final manifest = await ref.watch(manifestProvider.future);
  return manifest?.packVersion;
});
