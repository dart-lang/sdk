// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:yaml/yaml.dart';

extension YamlMapExtensions on YamlMap {
  /// Return the node representing the key that corresponds to the value
  /// represented by the [value] node.
  YamlNode keyAtValue(YamlNode value) {
    for (var entry in nodes.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  /// Return the value associated with the key whose value matches the given
  /// [key], or `null` if there is no matching key.
  YamlNode valueAt(String key) {
    for (var keyNode in nodes.keys) {
      if (keyNode is YamlScalar && keyNode.value == key) {
        return nodes[key];
      }
    }
    return null;
  }
}

extension YamlNodeExtensions on YamlNode {
  /// Return the child of this node that contains the given [offset], or `null`
  /// if none of the children contains the offset.
  YamlNode childContainingOffset(int offset) {
    var node = this;
    if (node is YamlList) {
      for (var element in node.nodes) {
        if (element.containsOffset(offset)) {
          return element;
        }
      }
      for (var element in node.nodes) {
        if (element is YamlScalar && element.value == null) {
          // TODO(brianwilkerson) Testing for a null value probably gets
          //  confused when there are multiple null values.
          return element;
        }
      }
    } else if (node is YamlMap) {
      for (var entry in node.nodes.entries) {
        if ((entry.key as YamlNode).containsOffset(offset)) {
          return entry.key;
        }
        var value = entry.value;
        if (value.containsOffset(offset) ||
            (value is YamlScalar && value.value == null)) {
          // TODO(brianwilkerson) Testing for a null value probably gets
          //  confused when there are multiple null values or when there is a
          //  null value before the node that actually contains the offset.
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Return `true` if this node contains the given [offset].
  bool containsOffset(int offset) {
    // TODO(brianwilkerson) Nodes at the end of the file contain any trailing
    //  whitespace. This needs to be accounted for, here or elsewhere.
    var nodeOffset = span.start.offset;
    var nodeEnd = nodeOffset + span.length;
    return nodeOffset <= offset && offset <= nodeEnd;
  }
}
