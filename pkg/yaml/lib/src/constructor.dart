// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.constructor;

import 'model.dart';
import 'visitor.dart';
import 'yaml_map.dart';

/// Takes a parsed and composed YAML document (what the spec calls the
/// "representation graph") and creates native Dart objects that represent that
/// document.
class Constructor extends Visitor {
  /// The root node of the representation graph.
  final Node _root;

  /// Map from anchor names to the most recent Dart node with that anchor.
  final _anchors = <String, dynamic>{};

  Constructor(this._root);

  /// Runs the Constructor to produce a Dart object.
  construct() => _root.visit(this);

  /// Returns the value of a scalar.
  visitScalar(ScalarNode scalar) => scalar.value;

  /// Converts a sequence into a List of Dart objects.
  visitSequence(SequenceNode seq) {
    var anchor = getAnchor(seq);
    if (anchor != null) return anchor;
    var dartSeq = setAnchor(seq, []);
    dartSeq.addAll(super.visitSequence(seq));
    return dartSeq;
  }

  /// Converts a mapping into a Map of Dart objects.
  visitMapping(MappingNode map) {
    var anchor = getAnchor(map);
    if (anchor != null) return anchor;
    var dartMap = setAnchor(map, new YamlMap());
    super.visitMapping(map).forEach((k, v) { dartMap[k] = v; });
    return dartMap;
  }

  /// Returns the Dart object that already represents [anchored], if such a
  /// thing exists.
  getAnchor(Node anchored) {
    if (anchored.anchor == null) return null;
    if (_anchors.containsKey(anchored.anchor)) return _anchors[anchored.anchor];
  }

  /// Records that [value] is the Dart object representing [anchored].
  setAnchor(Node anchored, value) {
    if (anchored.anchor == null) return value;
    _anchors[anchored.anchor] = value;
    return value;
  }
}
