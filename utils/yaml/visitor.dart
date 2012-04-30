// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The visitor pattern for YAML documents. */
class _Visitor {
  /** Returns [alias]. */
  visitAlias(_AliasNode alias) => alias;

  /** Returns [scalar]. */
  visitScalar(_ScalarNode scalar) => scalar;

  /** Visits each node in [seq] and returns a list of the results. */
  visitSequence(_SequenceNode seq) => seq.content.map((e) => e.visit(this));

  /** Visits each key and value in [map] and returns a map of the results. */
  visitMapping(_MappingNode map) {
    var out = new YamlMap();
    for (var key in map.content.getKeys()) {
      out[key.visit(this)] = map.content[key].visit(this);
    }
    return out;
  }
}
