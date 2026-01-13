import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'pack_storage_manager.dart';

/// GitHub repository information for pack downloads
class GitHubConfig {
  static const String owner = 'Shivansh-bind';
  static const String repo = 'my-docusaurus-site';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$owner/$repo/releases/latest';
}

/// Information about a release pack
class ReleaseInfo {
  final String tagName;
  final String packVersion;
  final String zipUrl;
  final String? manifestUrl;
  final int? sizeBytes;
  final DateTime publishedAt;

  ReleaseInfo({
    required this.tagName,
    required this.packVersion,
    required this.zipUrl,
    this.manifestUrl,
    this.sizeBytes,
    required this.publishedAt,
  });
}

/// Download progress callback
typedef DownloadProgressCallback = void Function(int received, int total);

/// Manages pack downloads from GitHub Releases
class PackDownloadManager {
  final PackStorageManager _storageManager;
  final http.Client _client;

  PackDownloadManager({
    PackStorageManager? storageManager,
    http.Client? client,
  })  : _storageManager = storageManager ?? PackStorageManager(),
        _client = client ?? http.Client();

  /// Fetch the latest release info from GitHub
  Future<ReleaseInfo?> getLatestReleaseInfo() async {
    try {
      final response = await _client.get(
        Uri.parse(GitHubConfig.releasesApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        debugPrint(
            'PackDownloadManager: Failed to fetch release: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final assets = json['assets'] as List<dynamic>? ?? [];

      // Find the zip file
      String? zipUrl;
      int? sizeBytes;
      String? manifestUrl;

      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final downloadUrl = asset['browser_download_url'] as String?;

        if (name.startsWith('release_pack_') && name.endsWith('.zip')) {
          zipUrl = downloadUrl;
          sizeBytes = asset['size'] as int?;
        } else if (name == 'index.json') {
          manifestUrl = downloadUrl;
        }
      }

      if (zipUrl == null) {
        debugPrint('PackDownloadManager: No pack ZIP found in release');
        return null;
      }

      final tagName = json['tag_name'] as String? ?? '';
      final publishedAtStr = json['published_at'] as String? ?? '';

      // Extract version from tag (e.g., "pack-v2026.01.13" -> "2026.01.13")
      final packVersion = tagName.replaceFirst('pack-v', '');

      return ReleaseInfo(
        tagName: tagName,
        packVersion: packVersion,
        zipUrl: zipUrl,
        manifestUrl: manifestUrl,
        sizeBytes: sizeBytes,
        publishedAt: DateTime.tryParse(publishedAtStr) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('PackDownloadManager: Error fetching release info: $e');
      return null;
    }
  }

  /// Check if an update is available
  Future<bool> hasUpdate() async {
    final releaseInfo = await getLatestReleaseInfo();
    if (releaseInfo == null) return false;

    final currentManifest = await _storageManager.getManifest();
    if (currentManifest == null) {
      // No pack installed, update available
      return true;
    }

    // Compare versions (simple string comparison works for YYYY.MM.DD format)
    return releaseInfo.packVersion.compareTo(currentManifest.packVersion) > 0;
  }

  /// Download and install the latest pack
  ///
  /// [onProgress] is called with (bytesReceived, totalBytes) during download
  /// Returns the installed pack version on success, or throws on failure
  Future<String> downloadAndInstall({
    DownloadProgressCallback? onProgress,
  }) async {
    // Step 1: Get release info
    final releaseInfo = await getLatestReleaseInfo();
    if (releaseInfo == null) {
      throw Exception('No release available');
    }

    debugPrint(
        'PackDownloadManager: Downloading pack v${releaseInfo.packVersion}');

    // Step 2: Clear any previous staging
    await _storageManager.clearStaged();

    // Step 3: Download ZIP to temp file
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/pack_download.zip');

    try {
      await _downloadFile(releaseInfo.zipUrl, zipFile, onProgress);
      debugPrint('PackDownloadManager: Download complete');

      // Step 4: Extract to packs/new/
      final newPackDir = await _storageManager.getNewPackDir();
      await _extractZip(zipFile, newPackDir);
      debugPrint('PackDownloadManager: Extraction complete');

      // Step 5: Validate and swap
      await _storageManager.swapPacks();
      debugPrint('PackDownloadManager: Pack installed successfully');

      // Step 6: Cleanup
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      await _storageManager.cleanup();

      return releaseInfo.packVersion;
    } catch (e) {
      // Cleanup on failure
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      await _storageManager.clearStaged();
      rethrow;
    }
  }

  /// Download a file with progress reporting
  Future<void> _downloadFile(
    String url,
    File destination,
    DownloadProgressCallback? onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final sink = destination.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress?.call(receivedBytes, totalBytes);
      }
    } finally {
      await sink.close();
    }
  }

  /// Extract ZIP archive to destination directory
  Future<void> _extractZip(File zipFile, Directory destination) async {
    // Read the ZIP file
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Ensure destination exists
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // Extract all files
    for (final file in archive) {
      final filename = file.name;

      // Handle the content/ prefix from the ZIP structure
      String outputPath = filename;
      if (filename.startsWith('content/')) {
        outputPath = filename.substring('content/'.length);
      }

      if (outputPath.isEmpty) continue;

      final outputFile = File('${destination.path}/$outputPath');

      if (file.isFile) {
        // Create parent directories if needed
        final parent = outputFile.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }

        // Write file content
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        // Create directory
        if (!await outputFile.exists()) {
          await Directory(outputFile.path).create(recursive: true);
        }
      }
    }

    debugPrint('PackDownloadManager: Extracted ${archive.length} entries');
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
