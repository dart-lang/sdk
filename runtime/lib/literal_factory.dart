// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Factory class constructing mutable List and Map objects from parser generated
// list and map literals.

class _LiteralFactory {
  // [elements] contains elements that are not yet type checked.
  factory List<E>.fromLiteral(int location,
                              String element_type,
                              List elements) {
    var len = elements.length;
    var list = new GrowableObjectArray<E>.withCapacity(len);
    for (int i = 0; i < len; i++) {
      // In checked mode only, rethrow a potential type error with a more user
      // friendly error message.
      try {
        list.backingArray[i] = elements[i];
      } catch (TypeError error) {
        TypeError._throwNew(location,
                            elements[i],
                            element_type,
                            "list literal element at index ${i}");
      }
    }
    list.length = len;
    return list;
  }

  // [elements] contains n key-value pairs.
  // The keys are at position 2*n and are already type checked by the parser
  // in checked mode.
  // The values are at position 2*n+1 and are not yet type checked.
  factory Map<K, V>.fromLiteral(int location,
                                String value_type,
                                List elements) {
    var map = new LinkedHashMap<String, V>();
    var len = elements.length;
    for (int i = 1; i < len; i += 2) {
      // The type of the key has been checked in the parser already.
      // In checked mode only, rethrow a potential type error with a more user
      // friendly error message.
      try {
        map[elements[i - 1]] = elements[i];
      } catch (TypeError error) {
        TypeError._throwNew(location,
                            elements[i],
                            value_type,
                            "map literal value at index ${i ~/ 2}");
      }
    }
    return map;
  }
}
