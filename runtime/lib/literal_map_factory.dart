// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Immutable map class for compiler generated map literals.

class _LiteralMapFactory {
  // [elements] contains n key-value pairs. The keys are at position
  // 2*n, the values at position 2*n+1.
  factory Map<K, V>.fromLiteral(int location,
                                String value_type,
                                List elements) {
    var map = new LinkedHashMap<String, V>();
    var len = elements.length;
    for (int i = 1; i < len; i += 2) {
      // The type of the key has been checked in the parser already.
      if (elements[i] is !V) {
        TypeError._throwNew(location,
                            elements[i],
                            value_type,
                            "map literal value at index ${i ~/ 2}");
      }
      map[elements[i-1]] = elements[i];
    }
    return map;
  }
}
