import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../features/library/domain/index_models.dart';

/// Manages pack storage directories and atomic pack swaps.
///
/// Directory structure:
/// ```
/// <app_data>/packs/
///   current/         <- Active pack (loaded by app)
///     index.json
///     docs/*.html
///     assets/
///   new/             <- Staging for downloads
///   old/             <- Backup before swap (for rollback)
/// ```
class PackStorageManager {
  static const String _packsDirName = 'packs';
  static const String _currentDirName = 'current';
  static const String _newDirName = 'new';
  static const String _oldDirName = 'old';
  static const String _manifestFileName = 'index.json';

  Directory? _packsDir;
  ContentManifest? _cachedManifest;

  /// Get the base packs directory
  Future<Directory> getPacksDir() async {
    if (_packsDir != null) return _packsDir!;

    final appDir = await getApplicationDocumentsDirectory();
    _packsDir = Directory('${appDir.path}/$_packsDirName');

    if (!await _packsDir!.exists()) {
      await _packsDir!.create(recursive: true);
    }

    return _packsDir!;
  }

  /// Get the current pack directory
  Future<Directory> getCurrentPackDir() async {
    final packsDir = await getPacksDir();
    return Directory('${packsDir.path}/$_currentDirName');
  }

  /// Get the new pack (staging) directory
  Future<Directory> getNewPackDir() async {
    final packsDir = await getPacksDir();
    return Directory('${packsDir.path}/$_newDirName');
  }

  /// Get the old pack (backup) directory
  Future<Directory> getOldPackDir() async {
    final packsDir = await getPacksDir();
    return Directory('${packsDir.path}/$_oldDirName');
  }

  /// Check if a valid pack exists in current/
  Future<bool> hasValidPack() async {
    try {
      final manifest = await getManifest();
      return manifest != null;
    } catch (e) {
      debugPrint('PackStorageManager: hasValidPack error: $e');
      return false;
    }
  }

  /// Get the manifest from current pack (cached after first load)
  Future<ContentManifest?> getManifest({bool forceReload = false}) async {
    if (_cachedManifest != null && !forceReload) {
      return _cachedManifest;
    }

    final currentDir = await getCurrentPackDir();
    final manifestFile = File('${currentDir.path}/$_manifestFileName');

    if (!await manifestFile.exists()) {
      debugPrint(
          'PackStorageManager: No manifest found at ${manifestFile.path}');
      return null;
    }

    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _cachedManifest = ContentManifest.fromJson(json);
      debugPrint(
          'PackStorageManager: Loaded manifest v${_cachedManifest!.packVersion}');
      return _cachedManifest;
    } catch (e) {
      debugPrint('PackStorageManager: Failed to parse manifest: $e');
      return null;
    }
  }

  /// Get the HTML file path for a given docId
  Future<String?> getDocHtmlPath(String docId) async {
    final manifest = await getManifest();
    if (manifest == null) return null;

    final doc = manifest.getDoc(docId);
    if (doc == null) return null;

    final currentDir = await getCurrentPackDir();
    final htmlPath = '${currentDir.path}/${doc.html}';

    final file = File(htmlPath);
    if (!await file.exists()) {
      debugPrint('PackStorageManager: HTML not found: $htmlPath');
      return null;
    }

    return htmlPath;
  }

  /// Get the file:// URI for a docId (for WebView loading)
  Future<Uri?> getDocUri(String docId) async {
    final htmlPath = await getDocHtmlPath(docId);
    if (htmlPath == null) return null;
    return Uri.file(htmlPath);
  }

  /// Validate a pack directory (check manifest exists and parses)
  /// Fix #4: Check that first 5 HTML files actually exist
  Future<bool> validatePack(Directory packDir) async {
    final manifestFile = File('${packDir.path}/$_manifestFileName');

    if (!await manifestFile.exists()) {
      debugPrint('PackStorageManager: Validation failed - no manifest');
      return false;
    }

    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final manifest = ContentManifest.fromJson(json);

      // Check that at least some docs are referenced
      if (manifest.docs.isEmpty) {
        debugPrint('PackStorageManager: Validation failed - empty docs');
        return false;
      }

      // Fix #4: Check that first 5 HTML files actually exist
      final docsToCheck = manifest.docs.values.take(5).toList();
      int missingCount = 0;

      for (final doc in docsToCheck) {
        final htmlPath = '${packDir.path}/${doc.html}';
        if (!await File(htmlPath).exists()) {
          debugPrint('PackStorageManager: Missing HTML: $htmlPath');
          missingCount++;
        }
      }

      // Fail if more than half of checked docs are missing
      if (missingCount > docsToCheck.length / 2) {
        debugPrint(
            'PackStorageManager: Validation failed - too many missing HTMLs ($missingCount/${docsToCheck.length})');
        return false;
      }

      debugPrint(
          'PackStorageManager: Validation passed for v${manifest.packVersion}');
      return true;
    } catch (e) {
      debugPrint('PackStorageManager: Validation failed - parse error: $e');
      return false;
    }
  }

  /// Atomically swap packs: new -> current (current -> old)
  ///
  /// 1. Validate new pack
  /// 2. Delete old (if exists)
  /// 3. Rename current -> old (if exists)
  /// 4. Rename new -> current
  /// 5. Clear manifest cache
  Future<void> swapPacks() async {
    final newDir = await getNewPackDir();
    final currentDir = await getCurrentPackDir();
    final oldDir = await getOldPackDir();

    // Step 1: Validate new pack
    if (!await validatePack(newDir)) {
      throw Exception('New pack validation failed');
    }

    // Step 2: Delete old pack if exists
    if (await oldDir.exists()) {
      await oldDir.delete(recursive: true);
      debugPrint('PackStorageManager: Deleted old pack');
    }

    // Step 3: Move current -> old (if current exists)
    if (await currentDir.exists()) {
      await currentDir.rename(oldDir.path);
      debugPrint('PackStorageManager: Moved current -> old');
    }

    // Step 4: Move new -> current
    await newDir.rename(currentDir.path);
    debugPrint('PackStorageManager: Moved new -> current');

    // Step 5: Clear cache
    _cachedManifest = null;

    debugPrint('PackStorageManager: Pack swap complete');
  }

  /// Rollback: restore old pack as current
  Future<bool> rollback() async {
    final currentDir = await getCurrentPackDir();
    final oldDir = await getOldPackDir();

    if (!await oldDir.exists()) {
      debugPrint('PackStorageManager: No old pack to rollback to');
      return false;
    }

    // Delete current if it exists (might be corrupt)
    if (await currentDir.exists()) {
      await currentDir.delete(recursive: true);
    }

    // Move old -> current
    await oldDir.rename(currentDir.path);
    _cachedManifest = null;

    debugPrint('PackStorageManager: Rollback complete');
    return true;
  }

  /// Clean up staging and backup directories
  Future<void> cleanup() async {
    final newDir = await getNewPackDir();
    final oldDir = await getOldPackDir();

    if (await newDir.exists()) {
      await newDir.delete(recursive: true);
      debugPrint('PackStorageManager: Cleaned up new pack');
    }

    if (await oldDir.exists()) {
      await oldDir.delete(recursive: true);
      debugPrint('PackStorageManager: Cleaned up old pack');
    }
  }

  /// Clear staged new pack (e.g., after failed download)
  Future<void> clearStaged() async {
    final newDir = await getNewPackDir();
    if (await newDir.exists()) {
      await newDir.delete(recursive: true);
    }
  }

  /// Get storage stats
  Future<Map<String, dynamic>> getStorageStats() async {
    final currentDir = await getCurrentPackDir();

    int totalSize = 0;
    int fileCount = 0;
    String? packVersion;

    if (await currentDir.exists()) {
      await for (final entity in currentDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;
        }
      }

      final manifest = await getManifest();
      packVersion = manifest?.packVersion;
    }

    return {
      'packVersion': packVersion,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'fileCount': fileCount,
      'hasValidPack': packVersion != null,
    };
  }
}
