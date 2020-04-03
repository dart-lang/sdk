// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

main() {
  runTests(<K, V>(entries) => Map<K, V>.fromEntries(entries));
  runTests(<K, V>(entries) => HashMap<K, V>.fromEntries(entries));
  runTests(<K, V>(entries) => LinkedHashMap<K, V>.fromEntries(entries));
}

void runTests(Map<K, V> Function<K, V>(Iterable<MapEntry<K, V>>) ctor) {
  fromEntriesTest(ctor);
  emptyIterableTest(ctor);
  equalElementsTest(ctor);
}

void fromEntriesTest(Map<K, V> Function<K, V>(Iterable<MapEntry<K, V>>) ctor) {
  var map = ctor([MapEntry(1, "one"), MapEntry(2, "two")]);
  Expect.equals(2, map.length);
  Expect.equals(2, map.keys.length);
  Expect.equals(2, map.values.length);
  Expect.equals("one", map[1]);
  Expect.equals("two", map[2]);
}

void emptyIterableTest(
    Map<K, V> Function<K, V>(Iterable<MapEntry<K, V>>) ctor) {
  var map = ctor([]);
  Expect.equals(0, map.length);
  Expect.equals(0, map.keys.length);
  Expect.equals(0, map.values.length);
}

void equalElementsTest(
    Map<K, V> Function<K, V>(Iterable<MapEntry<K, V>>) ctor) {
  var map =
      ctor([MapEntry(1, "one"), MapEntry(2, "two"), MapEntry(2, "other")]);
  Expect.equals(2, map.length);
  Expect.equals(2, map.keys.length);
  Expect.equals(2, map.values.length);
  Expect.equals("one", map[1]);
  Expect.equals("other", map[2]);
}
