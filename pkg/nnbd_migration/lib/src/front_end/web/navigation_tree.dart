// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Information about a node in the migration tool's navigation tree.
class NavigationTreeNode {
  /// Type of the node.
  final NavigationTreeNodeType type;

  /// Name of the node.
  final String name;

  /// If this is a directory node, list of nodes nested under this one.
  /// Otherwise `null`.
  final List<NavigationTreeNode> subtree;

  /// If this is a file node, full path to the file.  Otherwise `null`.
  final String path;

  /// If this is a file node, href that should be used if the file is clicked
  /// on, otherwise `null`.
  final String href;

  /// If this is a file node, number of edits that were made in the file,
  /// otherwise `null`.
  final int editCount;

  /// Creates a navigation tree node representing a directory.
  NavigationTreeNode.directory({@required this.name, @required this.subtree})
      : type = NavigationTreeNodeType.directory,
        path = null,
        href = null,
        editCount = null;

  /// Creates a navigation tree node representing a file.
  NavigationTreeNode.file(
      {@required this.name,
      @required this.path,
      @required this.href,
      @required this.editCount})
      : type = NavigationTreeNodeType.file,
        subtree = null;

  NavigationTreeNode.fromJson(dynamic json)
      : type = _decodeType(json['type'] as String),
        name = json['name'] as String,
        subtree = listFromJsonOrNull(json['subtree']),
        path = json['path'] as String,
        href = json['href'] as String,
        editCount = json['editCount'] as int;

  Map<String, Object> toJson() => {
        'type': _encodeType(type),
        'name': name,
        if (subtree != null) 'subtree': listToJson(subtree),
        if (path != null) 'path': path,
        if (href != null) 'href': href,
        if (editCount != null) 'editCount': editCount
      };

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

  static String _encodeType(NavigationTreeNodeType type) {
    switch (type) {
      case NavigationTreeNodeType.directory:
        return 'directory';
      case NavigationTreeNodeType.file:
        return 'file';
    }
    throw StateError('Unrecognized navigation tree node type: $type');
  }
}

/// Enum representing the different types of [NavigationTreeNode]s.
enum NavigationTreeNodeType {
  directory,
  file,
}
