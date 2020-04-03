// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// An object used to locate the [YamlNode] associated with a source range.
/// More specifically, it will return the deepest [YamlNode] which completely
/// encompasses the specified range.
class YamlNodeLocator {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// Initialize a newly created locator to locate the deepest [YamlNode] for
  /// which `node.offset <= [start]` and `[end] < node.end`.
  ///
  /// If the [end] offset is not provided, then it is considered the same as the
  /// [start] offset.
  YamlNodeLocator({@required int start, int end})
      : _startOffset = start,
        _endOffset = end ?? start;

  /// Search within the given Yaml [node] and return the path to the most deeply
  /// nested node that includes the whole target range, or an empty list if no
  /// node was found. The path is represented by all of the elements from the
  /// starting [node] to the most deeply nested node, in reverse order.
  List<YamlNode> searchWithin(YamlNode node) {
    var path = <YamlNode>[];
    _searchWithin(path, node);
    return path;
  }

  void _searchWithin(List<YamlNode> path, YamlNode node) {
    var span = node.span;
    if (span.start.offset > _endOffset || span.end.offset < _startOffset) {
      return;
    }
    if (node is YamlList) {
      for (var element in node.nodes) {
        _searchWithin(path, element);
        if (path.isNotEmpty) {
          path.add(node);
          return;
        }
      }
    } else if (node is YamlMap) {
      var nodeMap = node.nodes;
      for (YamlNode key in nodeMap.keys) {
        _searchWithin(path, key);
        if (path.isNotEmpty) {
          path.add(node);
          return;
        }
        _searchWithin(path, nodeMap[key]);
        if (path.isNotEmpty) {
          path.add(node);
          return;
        }
      }
    }
    path.add(node);
  }
}
