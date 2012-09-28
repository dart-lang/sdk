// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Factory classes constructing mutable List and Map objects from parser
// generated list and map literals.

class _ListLiteralFactory<E> {
  // [elements] contains elements that are already type checked.
  factory List.fromLiteral(List elements) {
    var list = new List<E>();
    if (elements.length > 0) {
      list._setData(elements);
      list.length = elements.length;
    }
    return list;
  }
}

// Factory class constructing mutable List and Map objects from parser generated
// list and map literals.

class _MapLiteralFactory<K, V> {
  // [elements] contains n key-value pairs.
  // The keys are at position 2*n and are already type checked by the parser
  // in checked mode.
  // The values are at position 2*n+1 and are not yet type checked.
  factory Map.fromLiteral(List elements) {
    var map = new LinkedHashMap<String, V>();
    var len = elements.length;
    for (int i = 1; i < len; i += 2) {
      map[elements[i - 1]] = elements[i];
    }
    return map;
  }
}

