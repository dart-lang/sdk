// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

// Test that a Map's keys, values and entries iterables are consistent with
// their map.
//
// While it is generally not permitted to modify a map while iterating the keys,
// values, or entries, it is possible to iterate these collections in between
// modifications of the map.
//
// See #48282

void check(String kind, Map m) {
  Expect.equals(0, m.length);

  // These existing iterables
  final keys = m.keys;
  final values = m.values;
  final entries = m.entries;

  for (int i = 0; i < 20; i++) {
    Expect.equals(i, m.length);

    // Fresh iterables.
    Expect.equals(i, m.keys.length);
    Expect.equals(i, m.values.length);
    Expect.equals(i, m.entries.length);

    Expect.equals(i, List.of(m.keys).length);
    Expect.equals(i, List.of(m.values).length);
    Expect.equals(i, List.of(m.entries).length);

    Expect.equals(i, iteratedLength(m.keys));
    Expect.equals(i, iteratedLength(m.values));
    Expect.equals(i, iteratedLength(m.entries));

    // Existing iterables.
    Expect.equals(i, keys.length);
    Expect.equals(i, values.length);
    Expect.equals(i, entries.length);

    Expect.equals(i, List.of(keys).length);
    Expect.equals(i, List.of(values).length);
    Expect.equals(i, List.of(entries).length);

    Expect.equals(i, iteratedLength(keys));
    Expect.equals(i, iteratedLength(values));
    Expect.equals(i, iteratedLength(entries));

    m[i] = i;
  }
}

int iteratedLength(Iterable iterable) {
  int length = 0;
  final iterator = iterable.iterator;
  while (iterator.moveNext()) {
    length++;
  }
  return length;
}

void main() {
  check('Map', {});
  check('Map.identity', Map.identity());
  check('HashMap', HashMap());
  check('HashMap.identity', HashMap.identity());
  check('SplayTreeMap', SplayTreeMap());
}
