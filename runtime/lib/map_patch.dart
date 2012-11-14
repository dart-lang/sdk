// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _HashMapImpl<K, V> {
  // Factory constructing a Map from a parser generated Map literal.
  // [elements] contains n key-value pairs.
  // The keys are at position 2*n and are already type checked by the parser
  // in checked mode.
  // The values are at position 2*n+1 and are not yet type checked.
  factory Map._fromLiteral(List elements) {
    var map = new LinkedHashMap<String, V>();
    var len = elements.length;
    for (int i = 1; i < len; i += 2) {
      map[elements[i - 1]] = elements[i];
    }
    return map;
  }
}
