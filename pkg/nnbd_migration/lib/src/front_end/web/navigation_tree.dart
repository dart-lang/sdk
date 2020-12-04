// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

class NavigationTreeDirectoryNode extends NavigationTreeNode {
  /// If this is a directory node, list of nodes nested under this one.
  /// Otherwise `null`.
  final List<NavigationTreeNode> subtree;

  /// Creates a navigation tree node representing a directory.
  NavigationTreeDirectoryNode(
      {@required String name, @required String path, @required this.subtree})
      : super._(name: name, path: path);

  /// Returns the status by examining [subtree]:
  ///
  /// * If all children nodes have the same status, then that status is returned.
  /// * Otherwise, if all children nodes are either 'alreadyMigrated' or
  ///   'migrating', then [UnitMigrationStatus.migrating] is returned.
  /// * Otherwise, if all children nodes are either 'alreadyMigrated' or
  ///   'opting out', then [UnitMigrationStatus.optingOut] is returned.
  /// * Otherwise, [UnitMigrationStatus.indeterminate] is returned.
  UnitMigrationStatus get migrationStatus {
    if (subtree.isEmpty) return UnitMigrationStatus.alreadyMigrated;
    var sharedStatus = subtree.first.migrationStatus;
    var allAreMigratedOrMigrating = true;
    var allAreMigratedOrOptingOut = true;
    for (var child in subtree) {
      var childMigrationStatus = child.migrationStatus;

      if (childMigrationStatus != sharedStatus) {
        sharedStatus = null;
      }
      if (childMigrationStatus != UnitMigrationStatus.alreadyMigrated &&
          childMigrationStatus != UnitMigrationStatus.migrating) {
        allAreMigratedOrMigrating = false;
      }
      if (childMigrationStatus != UnitMigrationStatus.alreadyMigrated &&
          childMigrationStatus != UnitMigrationStatus.optingOut) {
        allAreMigratedOrOptingOut = false;
      }
    }
    if (sharedStatus != null) {
      return sharedStatus;
    }
    if (allAreMigratedOrMigrating) {
      return UnitMigrationStatus.migrating;
    }
    if (allAreMigratedOrOptingOut) {
      // TODO(srawlins): Is this confusing? Should there be an 'optingOutStar'
      // which indicates that all opted out files will remain opted out, though
      // some files exist in the subtree which are already migrated.
      return UnitMigrationStatus.optingOut;
    }
    return UnitMigrationStatus.indeterminate;
  }

  NavigationTreeNodeType get type => NavigationTreeNodeType.directory;

  void setSubtreeParents() {
    if (subtree != null) {
      for (var child in subtree) {
        child.parent = this;
      }
    }
  }

  /// Toggle child nodes (recursively) to migrate to null safety.
  ///
  /// Only child nodes with 'opting out' or 'keep opted out' status are changed.
  void toggleChildrenToMigrate() {
    //assert(type == NavigationTreeNodeType.directory);
    for (var child in subtree) {
      if (child is NavigationTreeDirectoryNode) {
        child.toggleChildrenToMigrate();
      } else if (child is NavigationTreeFileNode &&
          child.migrationStatus == UnitMigrationStatus.optingOut) {
        child.migrationStatus = UnitMigrationStatus.migrating;
      }
    }
  }

  /// Toggle child nodes (recursively) to opt out of null safety.
  ///
  /// Only child nodes with 'migrating' status are changed.
  void toggleChildrenToOptOut() {
    for (var child in subtree) {
      if (child is NavigationTreeDirectoryNode) {
        child.toggleChildrenToOptOut();
      } else if (child is NavigationTreeFileNode &&
          child.migrationStatus == UnitMigrationStatus.migrating) {
        child.migrationStatus = UnitMigrationStatus.optingOut;
      }
    }
  }

  Map<String, Object> toJson() => {
        'type': 'directory',
        'name': name,
        'subtree': NavigationTreeNode.listToJson(subtree),
        if (path != null) 'path': path,
      };
}

class NavigationTreeFileNode extends NavigationTreeNode {
  /// If this is a file node, href that should be used if the file is clicked
  /// on, otherwise `null`.
  final String href;

  /// If this is a file node, number of edits that were made in the file,
  /// otherwise `null`.
  final int editCount;

  final bool wasExplicitlyOptedOut;

  UnitMigrationStatus migrationStatus;

  /// Creates a navigation tree node representing a file.
  NavigationTreeFileNode(
      {@required String name,
      @required String path,
      @required this.href,
      @required this.editCount,
      @required this.wasExplicitlyOptedOut,
      @required this.migrationStatus})
      : super._(name: name, path: path);

  NavigationTreeNodeType get type => NavigationTreeNodeType.file;

  Map<String, Object> toJson() => {
        'type': 'file',
        'name': name,
        if (path != null) 'path': path,
        if (href != null) 'href': href,
        if (editCount != null) 'editCount': editCount,
        if (wasExplicitlyOptedOut != null)
          'wasExplicitlyOptedOut': wasExplicitlyOptedOut,
        if (migrationStatus != null) 'migrationStatus': migrationStatus.index,
      };
}

/// Information about a node in the migration tool's navigation tree.
abstract class NavigationTreeNode {
  /// Name of the node.
  final String name;

  /// Parent of this node, or `null` if this is a top-level node.
  /*late final*/ NavigationTreeNode parent;

  /// Relative path to the file or directory from the package root.
  final String path;

  factory NavigationTreeNode.fromJson(dynamic json) {
    var type = _decodeType(json['type'] as String);
    if (type == NavigationTreeNodeType.directory) {
      return NavigationTreeDirectoryNode(
          name: json['name'] as String,
          path: json['path'] as String,
          subtree: listFromJsonOrNull(json['subtree']))
        ..setSubtreeParents();
    } else {
      return NavigationTreeFileNode(
          name: json['name'] as String,
          path: json['path'] as String,
          href: json['href'] as String,
          editCount: json['editCount'] as int,
          wasExplicitlyOptedOut: json['wasExplicitlyOptedOut'] as bool,
          migrationStatus:
              _decodeMigrationStatus(json['migrationStatus'] as int));
    }
  }

  NavigationTreeNode._({@required this.name, @required this.path});

  /// The migration status of the file or directory.
  UnitMigrationStatus get migrationStatus;

  NavigationTreeNodeType get type;

  Map<String, Object> toJson();

  /// Deserializes a list of navigation tree nodes from a JSON list.
  static List<NavigationTreeNode> listFromJson(dynamic json) =>
      [for (var node in json) NavigationTreeNode.fromJson(node)];

  /// Deserializes a list of navigation tree nodes from a possibly null JSON
  /// list.  If the argument is `null`, `null` is returned.
  static List<NavigationTreeNode> listFromJsonOrNull(dynamic json) =>
      json == null ? null : listFromJson(json);

  /// Serializes a list of navigation tree nodes into JSON.
  static List<Map<String, Object>> listToJson(List<NavigationTreeNode> nodes) =>
      [for (var node in nodes) node.toJson()];

  static UnitMigrationStatus _decodeMigrationStatus(int migrationStatus) {
    if (migrationStatus == null) return null;
    return UnitMigrationStatus.values[migrationStatus];
  }

  static NavigationTreeNodeType _decodeType(String json) {
    switch (json) {
      case 'directory':
        return NavigationTreeNodeType.directory;
      case 'file':
        return NavigationTreeNodeType.file;
      default:
        throw StateError('Unrecognized navigation tree node type: $json');
    }
  }
}

/// Enum representing the different types of [NavigationTreeNode]s.
enum NavigationTreeNodeType {
  directory,
  file,
}

/// Enum representing the different statuses a compilation unit can have.
enum UnitMigrationStatus {
  /// Indicates that a library was already migrated to null safety at the start
  /// of the current migration.
  alreadyMigrated,

  /// Indicates that a directory's status is indeterminate, because the statuses
  /// of it's children libraries (recursive) are mixed.
  indeterminate,

  /// Indicates that a library was not migrated to null safety at the start of
  /// the current migration (either the package was not opted in, or the library
  /// was explicitly opted out), and that the current migration does migrate the
  /// library.
  migrating,

  /// Indicates that the current migration opts the library out of null safety.
  ///
  /// This may mean that the library is explicitly opted out with a Dart
  /// language version comment, or that the package is currently opted out of
  /// null safety.
  optingOut,
}
