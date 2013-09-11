// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of hash set behavior, with focus in iteration and concurrent
// modification errors.

library hash_map2_test;
import "package:expect/expect.dart";
import 'dart:collection';

testSet(Set newSet(), Set newSetFrom(Set from)) {
  Set gen(int from, int to) =>
      new Set.from(new Iterable.generate(to - from, (n) => n + from));

  bool odd(int n) => (n & 1) == 1;
  bool even(int n) => (n & 1) == 0;

  {  // Test growing to largish capacity.
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

  {  // Test having many deleted elements.
    Set set = newSet();
    set.add(0);
    for (int i = 0; i < 1000; i++) {
      set.add(i + 1);
      set.remove(i);
      Expect.equals(1, set.length);
    }
  }

  {  // Test having many elements with same hashCode
    Set set = newSet();
    for (int i = 0; i < 1000; i++) {
      set.add(new BadHashCode());
    }
    Expect.equals(1000, set.length);
  }

  {  // Check concurrent modification
    Set set = newSet()..add(0)..add(1);

    {  // Test adding before a moveNext.
      Iterator iter = set.iterator;
      iter.moveNext();
      set.add(1);  // Updating existing key isn't a modification.
      iter.moveNext();
      set.add(2);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test adding after last element.
      Iterator iter = set.iterator;
      Expect.equals(3, set.length);
      iter.moveNext();
      iter.moveNext();
      iter.moveNext();
      set.add(3);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test removing during iteration.
      Iterator iter = set.iterator;
      iter.moveNext();
      set.remove(1000);  // Not a modification if it's not there.
      iter.moveNext();
      int n = iter.current;
      set.remove(n);
      // Removing doesn't change current.
      Expect.equals(n, iter.current);
      Expect.throws(iter.moveNext, (e) => e is Error);
    }

    {  // Test removing after last element.
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

    {  // Test that updating value doesn't cause error.
      Iterator iter = set.iterator;
      Expect.equals(2, set.length);
      iter.moveNext();
      int n = iter.current;
      set.add(n);
      iter.moveNext();
      Expect.isTrue(set.contains(iter.current));
    }

    {  // Check adding many existing values isn't considered modification.
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

  {  // Check that updating existing elements is not a modification.
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
        iter.moveNext();  // Should not throw.

        for (int j = 1; j < i; j++) {
          set.remove(j);
        }
        iter = set.iterator;
        set.add(0);
        iter.moveNext();  // Should not throw.
     }
  }

  {  // Check that null can be in the set.
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

  {  // Check that addAll and clear works.
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

  {  // Check that removeWhere and retainWhere work.
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
}

void main() {
  testSet(() => new HashSet(), (m) => new HashSet.from(m));
  testSet(() => new LinkedHashSet(), (m) => new LinkedHashSet.from(m));
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
