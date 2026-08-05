// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:yaml/yaml.dart';

bool _columnAllowed(int? cursorColumn, YamlNode node) {
  if (cursorColumn == null) return true;
  return cursorColumn >= node.span.start.column;
}

extension YamlNodeExtensions on YamlNode {
  /// Return the child of this node that contains the given [offset], or `null`
  /// if none of the children contains the offset.
  ///
  /// If [cursorColumn] is provided, block collection children whose content
  /// starts at a greater column than [cursorColumn] are excluded. This prevents
  /// a cursor at a lower indentation level (e.g. column 0 after an indented
  /// list) from being treated as inside the deeper block.
  YamlNode? childContainingOffset(int offset, {required int cursorColumn}) {
    var node = this;
    if (node is YamlList) {
      for (var element in node.nodes) {
        if (element.containsOffset(offset) &&
            _columnAllowed(cursorColumn, element)) {
          return element;
        }
      }
      for (var element in node.nodes) {
        if (element is YamlScalar && element.value == null) {
          // TODO(brianwilkerson): Testing for a null value probably gets
          //  confused when there are multiple null values.
          return element;
        }
      }
    } else if (node is YamlMap) {
      var entries = node.nodes.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i];
        var nextEntryOffset = i + 1 < entries.length
            ? (entries[i + 1].key as YamlNode).span.start.offset
            : null;
        var key = entry.key as YamlNode;
        if (key.containsOffset(offset)) {
          return key;
        }
        var value = entry.value;
        // Whether the cursor is after this key's end but before the value's
        // first element/entry, bounded by the next sibling key if present.
        // This handles the "gap" between `key:` and a block collection whose
        // first element has not yet been reached by the cursor.
        var cursorInGap =
            key.span.end.offset <= offset &&
            offset < value.span.start.offset &&
            (nextEntryOffset == null || offset < nextEntryOffset);
        if ((value.containsOffset(offset) &&
                _columnAllowed(cursorColumn, value)) ||
            (value is YamlScalar &&
                value.value == null &&
                // To match a null, we need to be the last node, or the offset
                // needs to be before the next key.
                (nextEntryOffset == null || offset < nextEntryOffset)) ||
            (cursorInGap &&
                _columnAllowed(cursorColumn, value) &&
                ((value is YamlList && value.nodes.isNotEmpty) ||
                    (value is YamlMap && value.nodes.isNotEmpty)))) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Return `true` if this node contains the given [offset].
  bool containsOffset(int offset) {
    // TODO(brianwilkerson): Nodes at the end of the file contain any trailing
    //  whitespace. This needs to be accounted for, here or elsewhere.
    var nodeOffset = span.start.offset;
    var nodeEnd = nodeOffset + span.length;
    return nodeOffset <= offset && offset <= nodeEnd;
  }
}
