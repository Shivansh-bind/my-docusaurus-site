/// Content pack manifest models for offline doc storage (v2.1).
///
/// These models represent the structure of index.json manifest
/// that is distributed with the content packs via GitHub Releases.
///
/// NEW in v2.1:
/// - sidebarTree: minimal sidebar navigation (essentials only)
/// - indexGraph: deep navigation (index → children)
/// - relations: prev/next/up links for unit docs

/// The main manifest model loaded from index.json
class ContentManifest {
  ContentManifest({
    required this.packVersion,
    required this.generatedAt,
    required this.docs,
    this.sidebarTree = const [],
    this.indexGraph = const {},
    this.relations,
    this.backlinksGraph = const {},
    // Legacy field (deprecated)
    this.tree = const [],
  });

  final String packVersion;
  final String generatedAt;
  final Map<String, DocEntry> docs;

  /// NEW v2.1: Minimal sidebar navigation (essentials only)
  final List<SidebarNode> sidebarTree;

  /// NEW v2.1: Deep navigation structure (indexDocId → [childDocIds])
  final Map<String, List<String>> indexGraph;

  /// NEW v2.1: Relations (prev/next/up for unit docs)
  final DocRelations? relations;

  /// NEW v2.1: Manual backlinks (optional curated links)
  final Map<String, List<Backlink>> backlinksGraph;

  /// Legacy tree field (deprecated, use sidebarTree)
  @Deprecated('Use sidebarTree instead')
  final List<TreeNode> tree;

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    final docsJson = json['docs'] as Map<String, dynamic>? ?? {};
    final sidebarTreeJson = json['sidebarTree'] as List<dynamic>? ?? [];
    final indexGraphJson = json['indexGraph'] as Map<String, dynamic>? ?? {};
    final relationsJson = json['relations'] as Map<String, dynamic>?;
    final backlinksJson = json['backlinksGraph'] as Map<String, dynamic>? ?? {};
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
      sidebarTree: sidebarTreeJson
          .map((e) => SidebarNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      indexGraph: indexGraphJson.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      ),
      relations:
          relationsJson != null ? DocRelations.fromJson(relationsJson) : null,
      backlinksGraph: backlinksJson.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((e) => Backlink.fromJson(e as Map<String, dynamic>))
              .toList(),
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
        'sidebarTree': sidebarTree.map((e) => e.toJson()).toList(),
        'indexGraph': indexGraph,
        if (relations != null) 'relations': relations!.toJson(),
        'backlinksGraph': backlinksGraph.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
      };

  /// Get a doc entry by its docId
  DocEntry? getDoc(String docId) => docs[docId];

  /// Check if a docId exists in this manifest
  bool hasDoc(String docId) => docs.containsKey(docId);

  /// Get children of an index doc from indexGraph
  List<String> getIndexChildren(String indexDocId) =>
      indexGraph[indexDocId] ?? [];

  /// Get navigation relations for a doc
  NextPrevUp? getRelations(String docId) => relations?.nextPrev[docId];

  /// Get backlinks for a doc
  List<Backlink> getBacklinks(String docId) => backlinksGraph[docId] ?? [];

  /// Check if this manifest has the new v2.1 format
  bool get hasNewFormat => sidebarTree.isNotEmpty || indexGraph.isNotEmpty;
}

/// A single document entry in the docs map
class DocEntry {
  DocEntry({
    required this.title,
    required this.category,
    required this.html,
    this.semester = 0,
    this.subject,
    this.order = 0,
    this.unit,
    this.isHub = false,
  });

  final String title;
  final String
      category; // 'unit', 'handout', 'notes', 'notesIndex', 'assignments', etc.
  final String html; // relative path: "docs/<docId>.html"
  final int semester;
  final String? subject;
  final int order;
  final int? unit; // Unit number for unit docs
  final bool isHub; // Whether this is a hub/index page

  factory DocEntry.fromJson(Map<String, dynamic> json) {
    return DocEntry(
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? json['type'] ?? 'content').toString(),
      html: (json['html'] ?? '').toString(),
      semester: (json['semester'] ?? 0) is int
          ? json['semester'] as int
          : int.tryParse((json['semester'] ?? '0').toString()) ?? 0,
      subject: json['subject']?.toString(),
      order: (json['order'] ?? 0) is int
          ? json['order'] as int
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      unit: json['unit'] is int ? json['unit'] as int : null,
      isHub: json['isHub'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'html': html,
        'semester': semester,
        if (subject != null) 'subject': subject,
        'order': order,
        if (unit != null) 'unit': unit,
        if (isHub) 'isHub': isHub,
      };
}

/// Unit info for unit docs
class UnitInfo {
  UnitInfo({required this.course, required this.number});

  final String course;
  final int number;

  factory UnitInfo.fromJson(Map<String, dynamic> json) => UnitInfo(
        course: (json['course'] ?? '').toString(),
        number: (json['number'] ?? 0) is int
            ? json['number'] as int
            : int.tryParse((json['number'] ?? '0').toString()) ?? 0,
      );

  Map<String, dynamic> toJson() => {'course': course, 'number': number};
}

/// A node in the sidebar tree (v2.1)
class SidebarNode {
  SidebarNode({
    required this.id,
    required this.title,
    this.docId,
    this.items = const [],
  });

  final String id;
  final String title;
  final String? docId; // If present, tapping opens this doc
  final List<SidebarNode> items; // Child nodes

  /// Whether this is a leaf node (has docId)
  bool get isLeaf => docId != null && items.isEmpty;

  /// Whether this is a branch node (has children)
  bool get isBranch => items.isNotEmpty;

  factory SidebarNode.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return SidebarNode(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      docId: json['docId']?.toString(),
      items: itemsJson
          .map((e) => SidebarNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
    };
    if (docId != null) map['docId'] = docId;
    if (items.isNotEmpty) {
      map['items'] = items.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

/// Relations container (v2.1)
class DocRelations {
  DocRelations({required this.nextPrev});

  final Map<String, NextPrevUp> nextPrev;

  factory DocRelations.fromJson(Map<String, dynamic> json) {
    final nextPrevJson = json['nextPrev'] as Map<String, dynamic>? ?? {};
    return DocRelations(
      nextPrev: nextPrevJson.map(
        (key, value) => MapEntry(
          key,
          NextPrevUp.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'nextPrev': nextPrev.map((key, value) => MapEntry(key, value.toJson())),
      };
}

/// Next/Prev/Up relations for a doc
class NextPrevUp {
  NextPrevUp({this.prev, this.next, this.up});

  final String? prev;
  final String? next;
  final String? up;

  factory NextPrevUp.fromJson(Map<String, dynamic> json) => NextPrevUp(
        prev: json['prev']?.toString(),
        next: json['next']?.toString(),
        up: json['up']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (prev != null) 'prev': prev,
        if (next != null) 'next': next,
        if (up != null) 'up': up,
      };
}

/// A backlink entry (v2.1)
class Backlink {
  Backlink({required this.label, required this.targetDocId});

  final String label;
  final String targetDocId;

  factory Backlink.fromJson(Map<String, dynamic> json) => Backlink(
        label: (json['label'] ?? '').toString(),
        targetDocId: (json['targetDocId'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'targetDocId': targetDocId,
      };
}

// ============================================================================
// Legacy models (kept for backward compatibility)
// ============================================================================

/// Navigation tree node with hubDocId support (Automation Level 2)
class TreeNode {
  TreeNode({
    required this.id,
    required this.title,
    this.docId,
    this.hubDocId,
    this.type,
    this.items = const [],
  });

  final String id;
  final String title;
  final String? docId; // Only for leaf nodes
  final String? hubDocId; // For parent nodes - opens this doc on tap
  final String? type; // 'semester', 'subject', 'folder', 'leaf'
  final List<TreeNode> items;

  /// Whether this is a leaf node (has docId, opens doc directly)
  bool get isLeaf => docId != null && items.isEmpty;

  /// Whether this is a parent node (has children or hubDocId)
  bool get isParent => items.isNotEmpty || hubDocId != null;

  /// Get the docId to open (hubDocId for parents, docId for leaves)
  String? get openDocId => docId ?? hubDocId;

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return TreeNode(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      docId: json['docId']?.toString(),
      hubDocId: json['hubDocId']?.toString(),
      type: json['type']?.toString(),
      items: itemsJson
          .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id, 'title': title};
    if (docId != null) map['docId'] = docId;
    if (hubDocId != null) map['hubDocId'] = hubDocId;
    if (type != null) map['type'] = type;
    if (items.isNotEmpty) {
      map['items'] = items.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

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

@Deprecated('Use SidebarNode instead')
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

@Deprecated('Use SidebarNode instead')
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

@Deprecated('Use SidebarNode instead')
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
