/// Content pack manifest models for offline doc storage.
///
/// These models represent the structure of index.json manifest
/// that is distributed with the content packs via GitHub Releases.

/// The main manifest model loaded from index.json
class ContentManifest {
  ContentManifest({
    required this.packVersion,
    required this.generatedAt,
    required this.docs,
    required this.tree,
  });

  final String packVersion;
  final String generatedAt;
  final Map<String, DocEntry> docs;
  final List<TreeNode> tree;

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    final docsJson = json['docs'] as Map<String, dynamic>? ?? {};
    final treeJson = json['tree'] as List<dynamic>? ?? [];

    return ContentManifest(
      packVersion: (json['packVersion'] ?? '').toString(),
      generatedAt: (json['generatedAt'] ?? '').toString(),
      docs: docsJson.map(
        (key, value) => MapEntry(
          key,
          DocEntry.fromJson(value as Map<String, dynamic>),
        ),
      ),
      tree: treeJson
          .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'packVersion': packVersion,
        'generatedAt': generatedAt,
        'docs': docs.map((key, value) => MapEntry(key, value.toJson())),
        'tree': tree.map((e) => e.toJson()).toList(),
      };

  /// Get a doc entry by its docId
  DocEntry? getDoc(String docId) => docs[docId];

  /// Check if a docId exists in this manifest
  bool hasDoc(String docId) => docs.containsKey(docId);
}

/// A single document entry in the docs map
class DocEntry {
  DocEntry({
    required this.title,
    required this.semester,
    required this.subject,
    required this.type,
    required this.order,
    required this.html,
  });

  final String title;
  final int semester;
  final String subject;
  final String type;
  final int order;
  final String html; // relative path: "docs/<docId>.html"

  factory DocEntry.fromJson(Map<String, dynamic> json) {
    return DocEntry(
      title: (json['title'] ?? '').toString(),
      semester: (json['semester'] ?? 0) is int
          ? json['semester'] as int
          : int.tryParse((json['semester'] ?? '0').toString()) ?? 0,
      subject: (json['subject'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      order: (json['order'] ?? 0) is int
          ? json['order'] as int
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      html: (json['html'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'semester': semester,
        'subject': subject,
        'type': type,
        'order': order,
        'html': html,
      };
}

/// A node in the navigation tree (semester, subject, or doc reference)
class TreeNode {
  TreeNode({
    required this.id,
    required this.title,
    this.docId,
    this.type,
    this.items = const [],
  });

  final String id;
  final String title;
  final String? docId; // If present, this is a leaf node pointing to a doc
  final String? type; // For leaf nodes: handout, notes, pyq, etc.
  final List<TreeNode> items; // Child nodes (empty for leaf nodes)

  /// Whether this is a leaf node (references a doc)
  bool get isLeaf => docId != null;

  /// Whether this is a branch node (has children)
  bool get isBranch => items.isNotEmpty;

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return TreeNode(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      docId: json['docId']?.toString(),
      type: json['type']?.toString(),
      items: itemsJson
          .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
    };
    if (docId != null) map['docId'] = docId;
    if (type != null) map['type'] = type;
    if (items.isNotEmpty) {
      map['items'] = items.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

// ============================================================================
// Legacy models (kept for backward compatibility during migration)
// ============================================================================

@Deprecated('Use ContentManifest instead')
class AppIndex {
  AppIndex({
    required this.appVersion,
    required this.generatedAt,
    required this.semesters,
  });

  final String appVersion;
  final String generatedAt;
  final List<Semester> semesters;

  factory AppIndex.fromJson(Map<String, dynamic> json) {
    final semestersJson = (json['semesters'] as List<dynamic>? ?? []);
    return AppIndex(
      appVersion: (json['appVersion'] ?? '1.0.0').toString(),
      generatedAt: (json['generatedAt'] ?? '').toString(),
      semesters: semestersJson
          .map((e) => Semester.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@Deprecated('Use TreeNode instead')
class Semester {
  Semester({required this.name, required this.subjects});
  final String name;
  final List<Subject> subjects;

  factory Semester.fromJson(Map<String, dynamic> json) {
    final subjectsJson = (json['subjects'] as List<dynamic>? ?? []);
    return Semester(
      name: (json['name'] ?? '').toString(),
      subjects: subjectsJson
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@Deprecated('Use TreeNode instead')
class Subject {
  Subject({required this.name, required this.sections});
  final String name;
  final List<Section> sections;

  factory Subject.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as List<dynamic>? ?? []);
    return Subject(
      name: (json['name'] ?? '').toString(),
      sections: sectionsJson
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@Deprecated('Use TreeNode instead')
class Section {
  Section({required this.name, required this.items});
  final String name;
  final List<LibraryItem> items;

  factory Section.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return Section(
      name: (json['name'] ?? '').toString(),
      items: itemsJson
          .map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@Deprecated('Use DocEntry instead')
class LibraryItem {
  LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.hash,
    required this.updatedAt,
    required this.sizeBytes,
  });

  final String id;
  final String title;
  final String type;
  final String url;
  final String hash;
  final String updatedAt;
  final int sizeBytes;

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? 'html_doc').toString(),
      url: (json['url'] ?? '').toString(),
      hash: (json['hash'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      sizeBytes: (json['sizeBytes'] ?? 0) is int
          ? json['sizeBytes'] as int
          : int.tryParse((json['sizeBytes'] ?? '0').toString()) ?? 0,
    );
  }
}
