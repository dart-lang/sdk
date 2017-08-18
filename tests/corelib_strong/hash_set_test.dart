// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=

// Tests of hash set behavior, with focus in iteration and concurrent
// modification errors.

library hash_map2_test;

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:math' as math;

testSet(Set newSet(), Set newSetFrom(Iterable from)) {
  Set gen(int from, int to) =>
      new Set.from(new Iterable.generate(to - from, (n) => n + from));

  bool odd(int n) => (n & 1) == 1;
  bool even(int n) => (n & 1) == 0;

  {
    // Test growing to largish capacity.
    Set set = newSet();

    for (int i = 0; i < 256; i++) {
      set.add(i);
    }

    set.addAll(gen(256, 512));
    set.addAll(newSetFrom(gen(512, 1000)));
    Expect.equals(1000, set.length);

    // Remove half.
    for (int i = 0; i < 1000; i += 2) set.remove(i);
    Expect.equals(500, set.length);
    Expect.isFalse(set.any(even));
    Expect.isTrue(set.every(odd));

    // Re-add all.
    set.addAll(gen(0, 1000));
    Expect.equals(1000, set.length);
  }

  {
    // Test having many deleted elements.
    Set set = newSet();
    set.add(0);
    for (int i = 0; i < 1000; i++) {
      set.add(i + 1);
      set.remove(i);
      Expect.equals(1, set.length);
    }
  }

  {
    // Test having many elements with same hashCode
    Set set = newSet();
    for (int i = 0; i < 1000; i++) {
      set.add(new BadHashCode());
    }
    Expect.equals(1000, set.length);
  }

  {
    // Check concurrent modification
    Set set = newSet()..add(0)..add(1);

    {
      // Test adding before a moveNext.
      Iterator iter = set.iterator;
      iter.moveNext();
      set.add(1); // Updating existing key isn't a modification.
      iter.moveNext();
      set.add(2);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {
      // Test adding after last element.
      Iterator iter = set.iterator;
      Expect.equals(3, set.length);
      iter.moveNext();
      iter.moveNext();
      iter.moveNext();
      set.add(3);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {
      // Test removing during iteration.
      Iterator iter = set.iterator;
      iter.moveNext();
      set.remove(1000); // Not a modification if it's not there.
      iter.moveNext();
      int n = iter.current;
      set.remove(n);
      // Removing doesn't change current.
      Expect.equals(n, iter.current);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {
      // Test removing after last element.
      Iterator iter = set.iterator;
      Expect.equals(3, set.length);
      iter.moveNext();
      iter.moveNext();
      iter.moveNext();
      int n = iter.current;
      set.remove(n);
      // Removing doesn't change current.
      Expect.equals(n, iter.current);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {
      // Test that updating value doesn't cause error.
      Iterator iter = set.iterator;
      Expect.equals(2, set.length);
      iter.moveNext();
      int n = iter.current;
      set.add(n);
      iter.moveNext();
      Expect.isTrue(set.contains(iter.current));
    }

    {
      // Check adding many existing values isn't considered modification.
      Set set2 = newSet();
      for (var value in set) {
        set2.add(value);
      }
      Iterator iter = set.iterator;
      set.addAll(set2);
      // Shouldn't throw.
      iter.moveNext();
    }
  }

  {
    // Check that updating existing elements is not a modification.
    // This must be the case even if the underlying data structure is
    // nearly full.
    for (int i = 1; i < 128; i++) {
      // Create maps of different sizes, some of which should be
      // at a limit of the underlying data structure.
      Set set = newSetFrom(gen(0, i));
      Iterator iter = set.iterator;
      for (int j = 0; j < i; j++) {
        set.add(j);
      }
      iter.moveNext(); // Should not throw.

      for (int j = 1; j < i; j++) {
        set.remove(j);
      }
      iter = set.iterator;
      set.add(0);
      iter.moveNext(); // Should not throw.
    }
  }

  {
    // Check that null can be in the set.
    Set set = newSet();
    set.add(null);
    Expect.equals(1, set.length);
    Expect.isTrue(set.contains(null));
    Expect.isNull(set.first);
    Expect.isNull(set.last);
    set.add(null);
    Expect.equals(1, set.length);
    Expect.isTrue(set.contains(null));
    set.remove(null);
    Expect.isTrue(set.isEmpty);
    Expect.isFalse(set.contains(null));

    // Created using Set.from.
    set = newSetFrom([null]);
    Expect.equals(1, set.length);
    Expect.isTrue(set.contains(null));
    Expect.isNull(set.first);
    Expect.isNull(set.last);
    set.add(null);
    Expect.equals(1, set.length);
    Expect.isTrue(set.contains(null));
    set.remove(null);
    Expect.isTrue(set.isEmpty);
    Expect.isFalse(set.contains(null));

    // Set that grows with null in it.
    set = newSetFrom([1, 2, 3, null, 4, 5, 6]);
    Expect.equals(7, set.length);
    for (int i = 7; i < 128; i++) {
      set.add(i);
    }
    Expect.equals(128, set.length);
    Expect.isTrue(set.contains(null));
    set.add(null);
    Expect.equals(128, set.length);
    Expect.isTrue(set.contains(null));
    set.remove(null);
    Expect.equals(127, set.length);
    Expect.isFalse(set.contains(null));
  }

  {
    // Check that addAll and clear works.
    Set set = newSet();
    set.addAll([]);
    Expect.isTrue(set.isEmpty);
    set.addAll([1, 3, 2]);
    Expect.equals(3, set.length);
    Expect.isTrue(set.contains(1));
    Expect.isTrue(set.contains(3));
    Expect.isTrue(set.contains(2));
    Expect.isFalse(set.contains(4));
    set.clear();
    Expect.isTrue(set.isEmpty);
  }

  {
    // Check that removeWhere and retainWhere work.
    Set set = newSetFrom([1, 2, 3]);
    set.removeWhere((each) => each == 2);
    Expect.equals(2, set.length);
    Expect.isTrue(set.contains(1));
    Expect.isFalse(set.contains(2));
    Expect.isTrue(set.contains(3));
    set.retainWhere((each) => each == 3);
    Expect.equals(1, set.length);
    Expect.isFalse(set.contains(1));
    Expect.isFalse(set.contains(2));
    Expect.isTrue(set.contains(3));
  }

  {
    // Test lookup
    Set set = newSet();
    var m1a = new Mutable(1);
    var m1b = new Mutable(1);
    var m2a = new Mutable(2);
    var m2b = new Mutable(2);
    Expect.isNull(set.lookup(m1a));
    Expect.isNull(set.lookup(m1b));
    set.add(m1a);
    Expect.identical(m1a, set.lookup(m1a));
    Expect.identical(m1a, set.lookup(m1b));

    Expect.isNull(set.lookup(m2a));
    Expect.isNull(set.lookup(m2b));
    set.add(m2a);
    Expect.identical(m2a, set.lookup(m2a));
    Expect.identical(m2a, set.lookup(m2b));

    set.add(m2b); // Adding doesn't change element.
    Expect.identical(m2a, set.lookup(m2a));
    Expect.identical(m2a, set.lookup(m2b));

    set.remove(m1a);
    set.add(m1b);
    Expect.identical(m1b, set.lookup(m1a));
    Expect.identical(m1b, set.lookup(m1b));

    set.add(1);
    Expect.identical(1, set.lookup(1.0));
    set.add(-0.0);
    Expect.identical(-0.0, set.lookup(0.0));
  }

  {
    // Test special hash codes
    Set set = newSet();
    List keys = [];
    // Powers of two
    for (int i = 63; i >= 2; --i) {
      keys.add(new Mutable(math.pow(2, i)));
    }
    for (var key in keys) {
      Expect.isTrue(set.add(key));
    }
    for (var key in keys) {
      Expect.isTrue(set.contains(key));
    }
  }
}

void testIdentitySet(Set create()) {
  Set set = create();
  set.add(1);
  set.add(2);
  set.add(1); // Integers are identical if equal.
  Expect.equals(2, set.length);
  var complex = 4;
  complex = set.length == 2 ? complex ~/ 4 : 87; // Avoid compile-time constant.
  Expect.isTrue(set.contains(complex)); // 1 is in set, even if computed.
  set.clear();

  // All compile time constants are identical to themselves.
  var constants = [
    double.INFINITY,
                   double.NAN, -0.0, //# 01: ok
    0.0, 42, "", null, false, true, #bif, testIdentitySet
  ];
  set.addAll(constants);
  Expect.equals(constants.length, set.length);
  for (var c in constants) {
    Expect.isTrue(set.contains(c), "constant: $c");
  }
  Expect.isTrue(set.containsAll(constants), "constants: $set");
  set.clear();

  var m1 = new Mutable(1);
  var m2 = new Mutable(2);
  var m3 = new Mutable(3);
  var m4 = new Mutable(2); // Equal to m2, but not identical.
  set.addAll([m1, m2, m3, m4]);
  Expect.equals(4, set.length);
  Expect.equals(3, m3.hashCode);
  m3.id = 1;
  Expect.equals(1, m3.hashCode);
  // Changing hashCode doesn't affect lookup.
  Expect.isTrue(set.contains(m3));
  Expect.isTrue(set.contains(m1));
  set.remove(m3);
  Expect.isFalse(set.contains(m3));
  Expect.isTrue(set.contains(m1));

  Expect.identical(m1, set.lookup(m1));
  Expect.identical(null, set.lookup(m3));
}

void main() {
  testSet(() => new Set(), (m) => new Set.from(m));
  testSet(() => new HashSet(), (m) => new HashSet.from(m));
  testSet(() => new LinkedHashSet(), (m) => new LinkedHashSet.from(m));
  testIdentitySet(() => new Set.identity());
  testIdentitySet(() => new HashSet.identity());
  testIdentitySet(() => new LinkedHashSet.identity());
  testIdentitySet(() => new HashSet(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
  testIdentitySet(() => new LinkedHashSet(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
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

class Mutable {
  int id;
  Mutable(this.id);
  int get hashCode => id;
  bool operator ==(other) => other is Mutable && id == other.id;
}
