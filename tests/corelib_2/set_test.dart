// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_test;

import 'package:expect/expect.dart';
import "dart:collection";

void testMain(Set create()) {
  testInts(create);
  testStrings(create);
  testInts(() => create().toSet());
  testStrings(() => create().toSet());
}

void testInts(Set create()) {
  Set set = create();

  testLength(0, set);
  Expect.isTrue(set.add(1));
  testLength(1, set);
  Expect.isTrue(set.contains(1));

  Expect.isFalse(set.add(1));
  testLength(1, set);
  Expect.isTrue(set.contains(1));

  Expect.isTrue(set.remove(1));
  testLength(0, set);
  Expect.isFalse(set.contains(1));

  Expect.isFalse(set.remove(1));
  testLength(0, set);
  Expect.isFalse(set.contains(1));

  for (int i = 0; i < 10; i++) {
    set.add(i);
  }

  testLength(10, set);
  for (int i = 0; i < 10; i++) {
    Expect.isTrue(set.contains(i));
  }

  testLength(10, set);

  for (int i = 10; i < 20; i++) {
    Expect.isFalse(set.contains(i));
  }

  // Test Set.forEach.
  int sum = 0;
  testForEach(int val) {
    sum += (val + 1);
  }

  set.forEach(testForEach);
  Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

  Expect.isTrue(set.containsAll(set));

  // Test Set.map.
  testMap(int val) {
    return val * val;
  }

  Set mapped = set.map(testMap).toSet();
  Expect.equals(10, mapped.length);

  Expect.isTrue(mapped.contains(0));
  Expect.isTrue(mapped.contains(1));
  Expect.isTrue(mapped.contains(4));
  Expect.isTrue(mapped.contains(9));
  Expect.isTrue(mapped.contains(16));
  Expect.isTrue(mapped.contains(25));
  Expect.isTrue(mapped.contains(36));
  Expect.isTrue(mapped.contains(49));
  Expect.isTrue(mapped.contains(64));
  Expect.isTrue(mapped.contains(81));

  sum = 0;
  set.forEach(testForEach);
  Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);

  sum = 0;

  mapped.forEach(testForEach);
  Expect.equals(1 + 2 + 5 + 10 + 17 + 26 + 37 + 50 + 65 + 82, sum);

  // Test Set.filter.
  testFilter(int val) {
    return val.isEven;
  }

  Set filtered = set.where(testFilter).toSet();

  Expect.equals(5, filtered.length);

  Expect.isTrue(filtered.contains(0));
  Expect.isTrue(filtered.contains(2));
  Expect.isTrue(filtered.contains(4));
  Expect.isTrue(filtered.contains(6));
  Expect.isTrue(filtered.contains(8));

  sum = 0;
  filtered.forEach(testForEach);
  Expect.equals(1 + 3 + 5 + 7 + 9, sum);

  Expect.isTrue(set.containsAll(filtered));

  // Test Set.every.
  testEvery(int val) {
    return (val < 10);
  }

  Expect.isTrue(set.every(testEvery));
  Expect.isTrue(filtered.every(testEvery));

  filtered.add(10);
  Expect.isFalse(filtered.every(testEvery));

  // Test Set.some.
  testSome(int val) {
    return (val == 4);
  }

  Expect.isTrue(set.any(testSome));
  Expect.isTrue(filtered.any(testSome));
  filtered.remove(4);
  Expect.isFalse(filtered.any(testSome));

  // Test Set.intersection.
  Set intersection = set.intersection(filtered);
  Expect.isTrue(set.contains(0));
  Expect.isTrue(set.contains(2));
  Expect.isTrue(set.contains(6));
  Expect.isTrue(set.contains(8));
  Expect.isFalse(intersection.contains(1));
  Expect.isFalse(intersection.contains(3));
  Expect.isFalse(intersection.contains(4));
  Expect.isFalse(intersection.contains(5));
  Expect.isFalse(intersection.contains(7));
  Expect.isFalse(intersection.contains(9));
  Expect.isFalse(intersection.contains(10));
  Expect.equals(4, intersection.length);

  Expect.isTrue(set.containsAll(intersection));
  Expect.isTrue(filtered.containsAll(intersection));

  // Test Set.union.
  Set twice = create()..addAll([0, 2, 4, 6, 8, 10, 12, 14]);
  Set thrice = create()..addAll([0, 3, 6, 9, 12, 15]);
  Set union = twice.union(thrice);
  Expect.equals(11, union.length);
  for (int i = 0; i < 16; i++) {
    Expect.equals(i.isEven || (i % 3) == 0, union.contains(i));
  }

  // Test Set.difference.
  Set difference = twice.difference(thrice);
  Expect.equals(5, difference.length);
  for (int i = 0; i < 16; i++) {
    Expect.equals(i.isEven && (i % 3) != 0, difference.contains(i));
  }
  Expect.isTrue(twice.difference(thrice).difference(twice).isEmpty);

  // Test Set.difference with non-element type.
  Set diffSet = create()..addAll([0, 1, 2, 499, 999]);
  Set<Object> objectSet = new Set<Object>();
  objectSet.add("foo");
  objectSet.add(499);
  Set diffResult = diffSet.difference(objectSet);
  Expect.equals(4, diffResult.length);
  for (int value in [0, 1, 2, 999]) {
    Expect.isTrue(diffResult.contains(value));
  }

  // Test Set.addAll.
  List list = new List(10);
  for (int i = 0; i < 10; i++) {
    list[i] = i + 10;
  }
  set.addAll(list);
  testLength(20, set);
  for (int i = 0; i < 20; i++) {
    Expect.isTrue(set.contains(i));
  }

  // Test Set.removeAll
  set.removeAll(list);
  testLength(10, set);
  for (int i = 0; i < 10; i++) {
    Expect.isTrue(set.contains(i));
  }
  for (int i = 10; i < 20; i++) {
    Expect.isFalse(set.contains(i));
  }

  // Test Set.clear.
  set.clear();
  testLength(0, set);
  Expect.isTrue(set.add(11));
  testLength(1, set);

  // Test Set.toSet.
  set.add(1);
  set.add(21);
  testLength(3, set);
  var set2 = set.toSet();
  testLength(3, set2);
  Expect.listEquals(set.toList(), set2.toList());
  set.add(31);
  testLength(4, set);
  testLength(3, set2);

  set2 = set.toSet()..clear();
  testLength(0, set2);
  Expect.isTrue(set2.add(11));
  Expect.isTrue(set2.add(1));
  Expect.isTrue(set2.add(21));
  Expect.isTrue(set2.add(31));
  testLength(4, set2);
  Expect.listEquals(set.toList(), set2.toList());

  set2 = (set.toSet()..clear()).toSet(); // Cloning empty set shouldn't fail.
  testLength(0, set2);
}

void testLength(int length, Set set) {
  Expect.equals(length, set.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(set.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(set.isNotEmpty);
  if (length == 0) {
    for (var e in set) {
      Expect.fail("contains element when iterated: $e");
    }
  }
  (length == 0 ? Expect.isFalse : Expect.isTrue)(set.iterator.moveNext());
}

void testStrings(Set create()) {
  var set = create();
  var strings = ["foo", "bar", "baz", "qux", "fisk", "hest", "svin", "pigvar"];
  set.addAll(strings);
  testLength(8, set);
  set.removeAll(strings.where((x) => x.length == 3));
  testLength(4, set);
  Expect.isTrue(set.add("bar"));
  Expect.isTrue(set.add("qux"));
  testLength(6, set);
  set.addAll(strings);
  testLength(8, set);
  set.removeWhere((x) => x.length != 3);
  testLength(4, set);
  set.retainWhere((x) => x[1] == "a");
  testLength(2, set);
  Expect.isTrue(set.containsAll(["baz", "bar"]));

  set = set.union(strings.where((x) => x.length != 3).toSet());
  testLength(6, set);
  set = set.intersection(["qux", "baz", "fisk", "egern"].toSet());
  testLength(2, set);
  Expect.isTrue(set.containsAll(["baz", "fisk"]));
}

void testTypeAnnotations(Set<int> set) {
  set.add(0);
  set.add(999);
  set.add(0x800000000);
  set.add(0x20000000000000);
  Expect.isFalse(set.contains("not an it"));
  Expect.isFalse(set.remove("not an it"));
  Expect.isFalse(set.containsAll(["Not an int", "Also no an int"]));

  testLength(4, set);
  set.removeAll(["Not an int", 999, "Also no an int"]);
  testLength(3, set);
  set.retainAll(["Not an int", 0, "Also no an int"]);
  testLength(1, set);
}

void testRetainWhere(
    Set<CE> create(
        [CEEq equals, CEHash hashCode, ValidKey validKey, CECompare compare])) {
  // The retainWhere method must not collapse the argument Iterable
  // in a way that doesn't match the equality of the set.
  // It must not throw away equal elements that are different in the
  // equality of the set.
  // It must not consider objects to be not there if they are equal
  // in the equality of the set.

  // If set equality is natural equality, using different but equal objects
  // must work. Can't use an identity set internally (as was done at some point
  // during development).
  var set = create();
  set.addAll([new CE(0), new CE(1), new CE(2)]);
  Expect.equals(3, set.length); // All different.
  set.retainAll([new CE(0), new CE(2)]);
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new CE(0)));
  Expect.isTrue(set.contains(new CE(2)));

  // If equality of set is identity, we can't internally use a non-identity
  // based set because it might throw away equal objects that are not identical.
  var elems = [new CE(0), new CE(1), new CE(2), new CE(0)];
  set = create(identical, null, null, identityCompare);
  set.addAll(elems);
  Expect.equals(4, set.length);
  set.retainAll([elems[0], elems[2], elems[3]]);
  Expect.equals(3, set.length);
  Expect.isTrue(set.contains(elems[0]));
  Expect.isTrue(set.contains(elems[2]));
  Expect.isTrue(set.contains(elems[3]));

  // If set equality is less precise than equality, we must not use equality
  // internally to see if the element is there:
  set = create(customEq(3), customHash(3), validKey, customCompare(3));
  set.addAll([new CE(0), new CE(1), new CE(2)]);
  Expect.equals(3, set.length);
  set.retainAll([new CE(3), new CE(5)]);
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new CE(6)));
  Expect.isTrue(set.contains(new CE(8)));

  // It shouldn't matter if the input is a set.
  set.clear();
  set.addAll([new CE(0), new CE(1), new CE(2)]);
  Expect.equals(3, set.length);
  set.retainAll(new Set.from([new CE(3), new CE(5)]));
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new CE(6)));
  Expect.isTrue(set.contains(new CE(8)));
}

void testDifferenceIntersection(create([equals, hashCode, validKey, compare])) {
  // Test that elements of intersection comes from receiver set.
  CE ce1a = new CE(1);
  CE ce1b = new CE(1);
  CE ce2 = new CE(2);
  CE ce3 = new CE(3);
  Expect.equals(ce1a, ce1b); // Sanity check.

  var set1 = create();
  var set2 = create();
  set1.add(ce1a);
  set1.add(ce2);
  set2.add(ce1b);
  set2.add(ce3);

  var difference = set1.difference(set2);
  testLength(1, difference);
  Expect.identical(ce2, difference.lookup(ce2));

  difference = set2.difference(set1);
  testLength(1, difference);
  Expect.identical(ce3, difference.lookup(ce3));

  // Difference uses other.contains to check for equality.
  var set3 = create(identical, identityHashCode, null, identityCompare);
  set3.add(ce1b);
  difference = set1.difference(set3);
  testLength(2, difference); // ce1a is not identical to element in set3.
  Expect.identical(ce1a, difference.lookup(ce1a));
  Expect.identical(ce2, difference.lookup(ce2));

  // Intersection always takes elements from receiver set.
  var intersection = set1.intersection(set2);
  testLength(1, intersection);
  Expect.identical(ce1a, intersection.lookup(ce1a));

  intersection = set1.intersection(set3);
  testLength(0, intersection);
}

// Objects that are equal based on data.
class CE implements Comparable<CE> {
  final int id;
  const CE(this.id);
  int get hashCode => id;
  bool operator ==(Object other) => other is CE && id == other.id;
  int compareTo(CE other) => id - other.id;
  String toString() => "CE($id)";
}

typedef int CECompare(CE e1, CE e2);
typedef int CEHash(CE e1);
typedef bool CEEq(CE e1, CE e2);
typedef bool ValidKey(Object o);
// Equality of Id objects based on id modulo value.
CEEq customEq(int mod) => (CE e1, CE e2) => ((e1.id - e2.id) % mod) == 0;
CEHash customHash(int mod) => (CE e) => e.id % mod;
CECompare customCompare(int mod) =>
    (CE e1, CE e2) => (e1.id % mod) - (e2.id % mod);
bool validKey(Object o) => o is CE;
final customId = new Map<dynamic, dynamic>.identity();
int counter = 0;
int identityCompare(e1, e2) {
  if (identical(e1, e2)) return 0;
  int i1 = customId.putIfAbsent(e1, () => ++counter);
  int i2 = customId.putIfAbsent(e2, () => ++counter);
  return i1 - i2;
}

void testIdentity(Set create()) {
  Set set = create();
  var e1 = new CE(0);
  var e2 = new CE(0);
  Expect.equals(e1, e2);
  Expect.isFalse(identical(e1, e2));

  testLength(0, set);
  set.add(e1);
  testLength(1, set);
  Expect.isTrue(set.contains(e1));
  Expect.isFalse(set.contains(e2));

  set.add(e2);
  testLength(2, set);
  Expect.isTrue(set.contains(e1));
  Expect.isTrue(set.contains(e2));

  var set2 = set.toSet();
  testLength(2, set2);
  Expect.isTrue(set2.contains(e1));
  Expect.isTrue(set2.contains(e2));
}

void testIntSetFrom(setFrom) {
  List<num> numList = [2, 3, 5, 7, 11, 13];

  Set<int> set1 = setFrom(numList);
  Expect.listEquals(numList, set1.toList()..sort());

  Set<num> numSet = numList.toSet();
  Set<int> set2 = setFrom(numSet);
  Expect.listEquals(numList, set2.toList()..sort());

  Iterable<num> numIter = numList.where((x) => true);
  Set<int> set3 = setFrom(numIter);
  Expect.listEquals(numList, set3.toList()..sort());

  Set<int> set4 = setFrom(new Iterable.generate(0));
  Expect.isTrue(set4.isEmpty);
}

void testCESetFrom(setFrom) {
  var ceList = [
    new CE(2),
    new CE(3),
    new CE(5),
    new CE(7),
    new CE(11),
    new CE(13)
  ];

  Set<CE> set1 = setFrom(ceList);
  Expect.listEquals(ceList, set1.toList()..sort());

  Set<CE> ceSet = ceList.toSet();
  Set<CE> set2 = setFrom(ceSet);
  Expect.listEquals(ceList, set2.toList()..sort());

  Iterable<CE> ceIter = ceList.where((x) => true);
  Set<CE> set3 = setFrom(ceIter);
  Expect.listEquals(ceList, set3.toList()..sort());

  Set<CE> set4 = setFrom(new Iterable.generate(0));
  Expect.isTrue(set4.isEmpty);
}

class A {}

class B {}

class C implements A, B {}

void testASetFrom(setFrom) {
  List<B> bList = <B>[new C()];
  // Set.from allows to cast elements.
  Set<A> aSet = setFrom(bList);
  Expect.isTrue(aSet.length == 1);
}

main() {
  testMain(() => new HashSet());
  testMain(() => new LinkedHashSet());
  testMain(() => new HashSet.identity());
  testMain(() => new LinkedHashSet.identity());
  testMain(() => new HashSet(equals: identical));
  testMain(() => new LinkedHashSet(equals: identical));
  testMain(() => new HashSet(
      equals: (a, b) => a == b,
      hashCode: (a) => -a.hashCode,
      isValidKey: (a) => true));
  testMain(() => new LinkedHashSet(
      equals: (a, b) => a == b,
      hashCode: (a) => -a.hashCode,
      isValidKey: (a) => true));
  testMain(() => new SplayTreeSet());

  testIdentity(() => new HashSet.identity());
  testIdentity(() => new LinkedHashSet.identity());
  testIdentity(() => new HashSet(equals: identical));
  testIdentity(() => new LinkedHashSet(equals: identical));
  testIdentity(() => new SplayTreeSet(identityCompare));

  testTypeAnnotations(new HashSet<int>());
  testTypeAnnotations(new LinkedHashSet<int>());
  testTypeAnnotations(new HashSet<int>(equals: identical));
  testTypeAnnotations(new LinkedHashSet<int>(equals: identical));
  testTypeAnnotations(new HashSet<int>(
      equals: (int a, int b) => a == b,
      hashCode: (int a) => a.hashCode,
      isValidKey: (a) => a is int));
  testTypeAnnotations(new LinkedHashSet<int>(
      equals: (int a, int b) => a == b,
      hashCode: (int a) => a.hashCode,
      isValidKey: (a) => a is int));
  testTypeAnnotations(new SplayTreeSet<int>());

  testRetainWhere(([equals, hashCode, validKey, comparator]) =>
      new HashSet(equals: equals, hashCode: hashCode, isValidKey: validKey));
  testRetainWhere(([equals, hashCode, validKey, comparator]) =>
      new LinkedHashSet(
          equals: equals, hashCode: hashCode, isValidKey: validKey));
  testRetainWhere(([equals, hashCode, validKey, comparator]) =>
      new SplayTreeSet(comparator, validKey));

  testDifferenceIntersection(([equals, hashCode, validKey, comparator]) =>
      new HashSet(equals: equals, hashCode: hashCode, isValidKey: validKey));
  testDifferenceIntersection(([equals, hashCode, validKey, comparator]) =>
      new LinkedHashSet(
          equals: equals, hashCode: hashCode, isValidKey: validKey));
  testDifferenceIntersection(([equals, hashCode, validKey, comparator]) =>
      new SplayTreeSet(comparator, validKey));

  testIntSetFrom((x) => new Set<int>.from(x));
  testIntSetFrom((x) => new HashSet<int>.from(x));
  testIntSetFrom((x) => new LinkedHashSet<int>.from(x));
  testIntSetFrom((x) => new SplayTreeSet<int>.from(x));

  testCESetFrom((x) => new Set<CE>.from(x));
  testCESetFrom((x) => new HashSet<CE>.from(x));
  testCESetFrom((x) => new LinkedHashSet<CE>.from(x));
  testCESetFrom((x) => new SplayTreeSet<CE>.from(x));

  testCESetFrom(
      (x) => new SplayTreeSet<CE>.from(x, customCompare(20), validKey));
  testCESetFrom((x) => new SplayTreeSet<CE>.from(x, identityCompare));

  testASetFrom((x) => new Set<A>.from(x));
  testASetFrom((x) => new HashSet<A>.from(x));
  testASetFrom((x) => new LinkedHashSet<A>.from(x));
  testASetFrom((x) => new SplayTreeSet<A>.from(x, identityCompare));
}
