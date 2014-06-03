// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.visitor;

import 'equality.dart';
import 'model.dart';

/// The visitor pattern for YAML documents.
class Visitor {
  /// Returns [alias].
  visitAlias(AliasNode alias) => alias;

  /// Returns [scalar].
  visitScalar(ScalarNode scalar) => scalar;

  /// Visits each node in [seq] and returns a list of the results.
  visitSequence(SequenceNode seq)
      => seq.content.map((e) => e.visit(this)).toList();

  /// Visits each key and value in [map] and returns a map of the results.
  visitMapping(MappingNode map) {
    var out = deepEqualsMap();
    for (var key in map.content.keys) {
      out[key.visit(this)] = map.content[key].visit(this);
    }
    return out;
  }
}
