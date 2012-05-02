// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Takes a parsed and composed YAML document (what the spec calls the
 * "representation graph") and creates native Dart objects that represent that
 * document.
 */
class _Constructor extends _Visitor {
  /** The root node of the representation graph. */
  _Node root;

  /** Map from anchor names to the most recent Dart node with that anchor. */
  Map<String, Dynamic> anchors;

  _Constructor(this.root) : this.anchors = {};

  /** Runs the Constructor to produce a Dart object. */
  construct() => root.visit(this);

  /** Returns the value of a scalar. */
  visitScalar(_ScalarNode scalar) => scalar.value;

  /** Converts a sequence into a List of Dart objects. */
  visitSequence(_SequenceNode seq) {
    var anchor = getAnchor(seq);
    if (anchor != null) return anchor;
    var dartSeq = setAnchor(seq, []);
    dartSeq.addAll(super.visitSequence(seq));
    return dartSeq;
  }

  /** Converts a mapping into a Map of Dart objects. */
  visitMapping(_MappingNode map) {
    var anchor = getAnchor(map);
    if (anchor != null) return anchor;
    var dartMap = setAnchor(map, new YamlMap());
    super.visitMapping(map).forEach((k, v) { dartMap[k] = v; });
    return dartMap;
  }

  /**
   * Returns the Dart object that already represents [anchored], if such a thing
   * exists.
   */
  getAnchor(_Node anchored) {
    if (anchored.anchor == null) return null;
    if (anchors.containsKey(anchored.anchor)) return anchors[anchored.anchor];
  }

  /** Records that [value] is the Dart object representing [anchored]. */
  setAnchor(_Node anchored, value) {
    if (anchored.anchor == null) return value;
    anchors[anchored.anchor] = value;
    return value;
  }
}
