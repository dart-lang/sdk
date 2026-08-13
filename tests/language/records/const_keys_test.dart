// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test for const Sets and Maps with Record keys.

import 'package:expect/expect.dart';

typedef IntInt = (int, int);

// Non-const Set with non-const elements. The const Sets below should behave
// like this one.
final s0 = {oneOne, twoTwo};

// 'Same' Set as a const Set with various element types. Some `Set`
// implementations use the element type to determine that an element is not in
// the set.
const s1 = <IntInt>{(1, 1), (2, 2)};
const s2 = <Record>{(1, 1), (2, 2)};
const s3 = <Object>{(1, 1), (2, 2)};

void testSetContains<K>(Set<K> set, Object? value, bool expected) {
  Expect.equals(expected, set.contains(value), '$set.contains($value)');
}

void testSet<K>(Set<K> set) {
  testSetContains(set, (1, 1), true);
  testSetContains(set, oneOne, true);
  testSetContains(set, (2, 2), true);
  testSetContains(set, twoTwo, true);
  testSetContains(set, (1, 2), false);
  testSetContains(set, oneTwo, false);
  testSetContains(set, (1, x: 2), false);
  testSetContains(set, (1, 'x'), false);
  testSetContains(set, 123, false);
}

void testSets() {
  testSet(s0);
  testSet(s1);
  testSet(s2);
  testSet(s3);
}

// Non-const Map with non-const keys.
final m0 = {oneOne: 'oneone', twoTwo: 'twotwo'};

// 'Same' Map as a const Map with various key types.  Some `Map` implementations
// use the key type to determine that an key is not in the set.
const m1 = <IntInt, Object>{(1, 1): 'oneone', (2, 2): 'twotwo'};
const m2 = <Record, Object>{(1, 1): 'oneone', (2, 2): 'twotwo'};
const m3 = <Object, Object>{(1, 1): 'oneone', (2, 2): 'twotwo'};

void testMapIndex<K, V>(Map<K, V> map, Object? index, V? expected) {
  Expect.equals(expected, map[index], '$map[$index]');
}

void testMap<K, V>(Map<K, V> map) {
  testMapIndex(map, (1, 1), 'oneone');
  testMapIndex(map, oneOne, 'oneone');
  testMapIndex(map, (2, 2), 'twotwo');
  testMapIndex(map, twoTwo, 'twotwo');
  testMapIndex(map, (1, 2), null);
  testMapIndex(map, oneTwo, null);
  testMapIndex(map, (1, x: 2), null);
  testMapIndex(map, (1, 'x'), null);
  testMapIndex(map, 123, null);
}

void testMaps() {
  testMap(m0);
  testMap(m1);
  testMap(m2);
  testMap(m3);
}

// 'never-inline' to prevent constant-folding the boxing of a record to a const
// record.
@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
(A, B) makePair<A, B>(A a, B b) => (a, b);

// These variables contain boxed records.
Object? oneOne;
Object? twoTwo;
Object? oneTwo;

void main() {
  oneOne = makePair(1, 1);
  twoTwo = makePair(2, 2);
  oneTwo = makePair(1, 2);

  testSets();
  testMaps();
}
