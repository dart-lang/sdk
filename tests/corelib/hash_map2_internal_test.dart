// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This copy of hash_map2_test exercises the internal Map implementation. 
// VMOptions=--use_internal_hash_map

// Tests of hash map behavior, with focus in iteration and concurrent
// modification errors.

library hash_map2_test;
import "package:expect/expect.dart";
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

    {  // Test that updating value of existing key doesn't cause concurrent
       // modification error.
      Iterator iter = map.keys.iterator;
      Expect.equals(2, map.length);
      iter.moveNext();
      int n = iter.current;
      map[n] = n * 2;
      iter.moveNext();
      Expect.equals(map[iter.current], iter.current);
    }

    {  // Test that modification during putIfAbsent is not an error.
      map.putIfAbsent(4, () {
        map[5] = 5;
        map[4] = -1;
        return 4;
      });
      Expect.equals(4, map[4]);
      Expect.equals(5, map[5]);
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

  {  // Regression test for bug in putIfAbsent where adding an element
     // that make the table grow, can be lost.
    Map map = newMap();
    map.putIfAbsent("S", () => 0);
    map.putIfAbsent("T", () => 0);
    map.putIfAbsent("U", () => 0);
    map.putIfAbsent("C", () => 0);
    map.putIfAbsent("a", () => 0);
    map.putIfAbsent("b", () => 0);
    map.putIfAbsent("n", () => 0);
    Expect.isTrue(map.containsKey("n"));
  }

  {  // Check that putIfAbsent works just as well as put.
    Map map = newMap();
    for (int i = 0; i < 128; i++) {
      map.putIfAbsent(i, () => i);
      Expect.isTrue(map.containsKey(i));
      map.putIfAbsent(i >> 1, () => -1);  // Never triggers.
    }
    for (int i = 0; i < 128; i++) {
      Expect.equals(i, map[i]);
    }
  }

  {  // Check that updating existing elements is not a modification.
     // This must be the case even if the underlying data structure is
     // nearly full.
     for (int i = 1; i < 128; i++) {
        // Create maps of different sizes, some of which should be
        // at a limit of the underlying data structure.
        Map map = newMapFrom(gen(0, i));

        // ForEach-iteration.
        map.forEach((key, v) {
          Expect.equals(key, map[key]);
          map[key] = key + 1;
          map.remove(1000);  // Removing something not there.
          map.putIfAbsent(key, () => Expect.fail("SHOULD NOT BE ABSENT"));
          // Doesn't cause ConcurrentModificationError.
        });

        // for-in iteration.
        for (int key in map.keys) {
          Expect.equals(key + 1, map[key]);
          map[key] = map[key] + 1;
          map.remove(1000);  // Removing something not there.
          map.putIfAbsent(key, () => Expect.fail("SHOULD NOT BE ABSENT"));
          // Doesn't cause ConcurrentModificationError.
        }

        // Raw iterator.
        Iterator iter = map.keys.iterator;
        for (int key = 0; key < i; key++) {
          Expect.equals(key + 2, map[key]);
          map[key] = key + 3;
          map.remove(1000);  // Removing something not there.
          map.putIfAbsent(key, () => Expect.fail("SHOULD NOT BE ABSENT"));
          // Doesn't cause ConcurrentModificationError on the moveNext.
        }
        iter.moveNext();  // Should not throw.

        // Remove a lot of elements, which can cause a re-tabulation.
        for (int key = 1; key < i; key++) {
          Expect.equals(key + 3, map[key]);
          map.remove(key);
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
  Expect.isTrue(new HashMap<int, String>() is Map<int, String>);
  Expect.isTrue(new LinkedHashMap<int, String>() is Map<int, String>);
  Expect.isTrue(new HashMap<String, int>.from({}) is Map<String, int>);
  Expect.isTrue(new LinkedHashMap<String, int>.from({}) is Map<String, int>);
  Expect.isTrue(<String, int>{} is Map<String, int>);
  Expect.isTrue(const <String, int>{} is Map<String, int>);

  testMap(() => new HashMap(), (m) => new HashMap.from(m));
  testMap(() => new LinkedHashMap(), (m) => new LinkedHashMap.from(m));
}


class BadHashCode {
  static int idCounter = 0;
  final int id;
  BadHashCode() : id = idCounter++;
  int get hashCode => 42;
}
