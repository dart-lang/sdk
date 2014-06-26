// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.constructor;

import 'equality.dart';
import 'model.dart';
import 'visitor.dart';
import 'yaml_node.dart';

/// Takes a parsed and composed YAML document (what the spec calls the
/// "representation graph") and creates native Dart objects that represent that
/// document.
class Constructor extends Visitor {
  /// The root node of the representation graph.
  final Node _root;

  /// Map from anchor names to the most recent Dart node with that anchor.
  final _anchors = <String, YamlNode>{};

  Constructor(this._root);

  /// Runs the Constructor to produce a Dart object.
  YamlNode construct() => _root.visit(this);

  /// Returns the value of a scalar.
  YamlScalar visitScalar(ScalarNode scalar) =>
      new YamlScalar.internal(scalar.value, scalar.span);

  /// Converts a sequence into a List of Dart objects.
  YamlList visitSequence(SequenceNode seq) {
    var anchor = getAnchor(seq);
    if (anchor != null) return anchor;
    var nodes = [];
    var dartSeq = setAnchor(seq, new YamlList.internal(nodes, seq.span));
    nodes.addAll(super.visitSequence(seq));
    return dartSeq;
  }

  /// Converts a mapping into a [Map] of Dart objects.
  YamlMap visitMapping(MappingNode map) {
    var anchor = getAnchor(map);
    if (anchor != null) return anchor;
    var nodes = deepEqualsMap();
    var dartMap = setAnchor(map, new YamlMap.internal(nodes, map.span));
    super.visitMapping(map).forEach((k, v) => nodes[k] = v);
    return dartMap;
  }

  /// Returns a new Dart object wrapping the object that already represents
  /// [anchored], if such a thing exists.
  YamlNode getAnchor(Node anchored) {
    if (anchored.anchor == null) return null;
    var value = _anchors[anchored.anchor];
    if (value == null) return null;

    // Re-wrap [value]'s contents so that it's associated with the span of the
    // anchor rather than its original definition.
    if (value is YamlMap) {
      return new YamlMap.internal(value.nodes, anchored.span);
    } else if (value is YamlList) {
      return new YamlList.internal(value.nodes, anchored.span);
    } else {
      assert(value is YamlScalar);
      return new YamlScalar.internal(value.value, anchored.span);
    }
  }

  /// Records that [value] is the Dart object representing [anchored].
  YamlNode setAnchor(Node anchored, YamlNode value) {
    if (anchored.anchor == null) return value;
    _anchors[anchored.anchor] = value;
    return value;
  }
}
