// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of hash map behavior, with focus in iteration and concurrent
// modification errors.

library hash_map2_test;
import 'dart:collection';

testMap(Map newMap(), Map newMapFrom(Map map)) {
  Map gen(int from, int to) {
    Map map = new LinkedHashMap();
    for (int i = from; i < to; i++) map[i] = i;
    return map;
  }

  bool odd(int n) => (n & 1) == 1;
  bool even(int n) => (n & 1) == 0;
  void addAll(Map toMap, Map fromMap) {
    fromMap.forEach((k, v) { toMap[k] = v; });
  }

  {  // Test growing to largish capacity.
    Map map = newMap();

    for (int i = 0; i < 256; i++) {
      map[i] = i;
    }
    addAll(map, gen(256, 512));
    addAll(map, newMapFrom(gen(512, 1000)));
    Expect.equals(1000, map.length);

    // Remove half.
    for (int i = 0; i < 1000; i += 2) map.remove(i);
    Expect.equals(500, map.length);
    Expect.isFalse(map.keys.any(even));
    Expect.isTrue(map.keys.every(odd));

    // Re-add all.
    addAll(map, gen(0, 1000));
    Expect.equals(1000, map.length);
  }

  {  // Test having many deleted elements.
    Map map = newMap();
    map[0] = 0;
    for (int i = 0; i < 1000; i++) {
      map[i + 1] = i + 1;
      map.remove(i);
      Expect.equals(1, map.length);
    }
  }

  {  // Test having many elements with same hashCode
    Map map = newMap();
    for (int i = 0; i < 1000; i++) {
      map[new BadHashCode()] = 0;
    }
    Expect.equals(1000, map.length);
  }

  {  // Check concurrent modification
    Map map = newMap()..[0] = 0..[1] = 1;

    {  // Test adding before a moveNext.
      Iterator iter = map.keys.iterator;
      iter.moveNext();
      map[1] = 9;  // Updating existing key isn't a modification.
      iter.moveNext();
      map[2] = 2;
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test adding after last element.
      Iterator iter = map.keys.iterator;
      Expect.equals(3, map.length);
      iter.moveNext();
      iter.moveNext();
      iter.moveNext();
      map[3] = 3;
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test removing during iteration.
      Iterator iter = map.keys.iterator;
      iter.moveNext();
      map.remove(1000);  // Not a modification if it's not there.
      iter.moveNext();
      int n = iter.current;
      map.remove(n);
      // Removing doesn't change current.
      Expect.equals(n, iter.current);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test removing after last element.
      Iterator iter = map.keys.iterator;
      Expect.equals(3, map.length);
      iter.moveNext();
      iter.moveNext();
      iter.moveNext();
      int n = iter.current;
      map.remove(n);
      // Removing doesn't change current.
      Expect.equals(n, iter.current);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test that updating value doesn't cause error.
      Iterator iter = map.keys.iterator;
      Expect.equals(2, map.length);
      iter.moveNext();
      int n = iter.current;
      map[n] = n * 2;
      iter.moveNext();
      Expect.equals(map[iter.current], iter.current);
    }

    {  // Test that modification during putIfAbsent is error
      Expect.throws(() => map.putIfAbsent(4, () {
        map[5] = 5;
        return 4;
      }), (e) => e is Error);
      Expect.isFalse(map.containsKey(4));
      Expect.isTrue(map.containsKey(5));
    }

    {  // Check adding many existing keys isn't considered modification.
      Map map2 = newMap();
      for (var key in map.keys) {
        map2[key] = map[key] + 1;
      }
      Iterator iter = map.keys.iterator;
      addAll(map, map2);
      // Shouldn't throw.
      iter.moveNext();
    }
  }

  {  // Check that updating existing elements is not a modification.
     // This must be the case even if the underlying data structure is
     // nearly full.
     for (int i = 1; i < 128; i++) {
        // Create maps of different sizes, some of which should be
        // at a limit of the underlying data structure.
        Map map = newMapFrom(gen(0, i));
        Iterator iter = map.keys.iterator;
        for (int j = 0; j < i; j++) {
          map[j] = j + 1;
        }
        iter.moveNext();  // Should not throw.

        for (int j = 1; j < i; j++) {
          map.remove(j);
        }
        iter = map.keys.iterator;
        map[0] = 2;
        iter.moveNext();  // Should not throw.
     }
  }

  {  // Check that null can be in the map.
    Map map = newMap();
    map[null] = 0;
    Expect.equals(1, map.length);
    Expect.isTrue(map.containsKey(null));
    Expect.isNull(map.keys.first);
    Expect.isNull(map.keys.last);
    map[null] = 1;
    Expect.equals(1, map.length);
    Expect.isTrue(map.containsKey(null));
    map.remove(null);
    Expect.isTrue(map.isEmpty);
    Expect.isFalse(map.containsKey(null));

    // Created using map.from.
    map = newMapFrom(new Map()..[null] = 0);
    Expect.equals(1, map.length);
    Expect.isTrue(map.containsKey(null));
    Expect.isNull(map.keys.first);
    Expect.isNull(map.keys.last);
    map[null] = 1;
    Expect.equals(1, map.length);
    Expect.isTrue(map.containsKey(null));
    map.remove(null);
    Expect.isTrue(map.isEmpty);
    Expect.isFalse(map.containsKey(null));

    Map fromMap = new Map();
    fromMap[1] = 0;
    fromMap[2] = 0;
    fromMap[3] = 0;
    fromMap[null] = 0;
    fromMap[4] = 0;
    fromMap[5] = 0;
    fromMap[6] = 0;
    Expect.equals(7, fromMap.length);

    // map that grows with null in it.
    map = newMapFrom(fromMap);
    Expect.equals(7, map.length);
    for (int i = 7; i < 128; i++) {
      map[i] = 0;
    }
    Expect.equals(128, map.length);
    Expect.isTrue(map.containsKey(null));
    map[null] = 1;
    Expect.equals(128, map.length);
    Expect.isTrue(map.containsKey(null));
    map.remove(null);
    Expect.equals(127, map.length);
    Expect.isFalse(map.containsKey(null));
  }
}

void main() {
  testMap(() => new HashMap(), (m) => new HashMap.from(m));
  testMap(() => new LinkedHashMap(), (m) => new LinkedHashMap.from(m));
}


class BadHashCode {
  static int idCounter = 0;
  final int id;
  BadHashCode() : id = idCounter++;
  int get hashCode => 42;
  // operator == is identity.
  // Can't make a bad compareTo that isn't invalid.
  int compareTo(BadHashCode other) => id - other.id;
}
