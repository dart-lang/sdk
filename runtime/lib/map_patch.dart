// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class Map<K, V> {
  // Factory constructing a Map from a parser generated Map literal.
  // [elements] contains n key-value pairs.
  // The keys are at position 2*n and are already type checked by the parser
  // in checked mode.
  // The values are at position 2*n+1 and are not yet type checked.
  factory Map._fromLiteral(List elements) {
    var map = new LinkedHashMap<K, V>();
    var len = elements.length;
    for (int i = 1; i < len; i += 2) {
      map[elements[i - 1]] = elements[i];
    }
    return map;
  }

  @patch
  factory Map.unmodifiable(Map other) {
    return new UnmodifiableMapView<K, V>(new Map.from(other));
  }

  @patch
  factory Map() = LinkedHashMap<K, V>;
}
