// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_test;


import 'package:expect/expect.dart';
import "dart:collection";

void testMain(Set create()) {
  testInts(create);
  testStrings(create);
}

void testInts(Set create()) {
  Set set = create();

  testLength(0, set);
  set.add(1);
  testLength(1, set);
  Expect.isTrue(set.contains(1));

  set.add(1);
  testLength(1, set);
  Expect.isTrue(set.contains(1));

  set.remove(1);
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
  set.add(11);
  testLength(1, set);
}

void testLength(int length, Set set) {
  Expect.equals(length, set.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(set.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(set.isNotEmpty);
  if (length == 0) {
    for (var e in set) { Expect.fail("contains element when iterated: $e"); }
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
  set.add("bar");
  set.add("qux");
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

void testRetainWhere(Set create([equals, hashCode, validKey])) {
  // The retainWhere method must not collapse the argument Iterable
  // in a way that doesn't match the equality of the set.
  // It must not throw away equal elements that are different in the
  // equality of the set.
  // It must not consider objects to be not there if they are equal
  // in the equality of the set.

  // If set equality is natural equality, using different but equal objects
  // must work. Can't use an identity set internally (as was done at some point
  // during development).
  Set set = create();
  set.addAll([new EO(0), new EO(1), new EO(2)]);
  Expect.equals(3, set.length);  // All different.
  set.retainAll([new EO(0), new EO(2)]);
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new EO(0)));
  Expect.isTrue(set.contains(new EO(2)));

  // If equality of set is identity, we can't internally use a non-identity
  // based set because it might throw away equal objects that are not identical.
  var elems = [new EO(0), new EO(1), new EO(2), new EO(0)];
  set = create(identical);
  set.addAll(elems);
  Expect.equals(4, set.length);
  set.retainAll([elems[0], elems[2], elems[3]]);
  Expect.equals(3, set.length);
  Expect.isTrue(set.contains(elems[0]));
  Expect.isTrue(set.contains(elems[2]));
  Expect.isTrue(set.contains(elems[3]));

  // If set equality is less precise than equality, we must not use equality
  // internally to see if the element is there:
  set = create(customEq(3), customHash(3), validKey);
  set.addAll([new EO(0), new EO(1), new EO(2)]);
  Expect.equals(3, set.length);
  set.retainAll([new EO(3), new EO(5)]);
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new EO(6)));
  Expect.isTrue(set.contains(new EO(8)));

  // It shouldn't matter if the input is a set.
  set.clear();
  set.addAll([new EO(0), new EO(1), new EO(2)]);
  Expect.equals(3, set.length);
  set.retainAll(new Set.from([new EO(3), new EO(5)]));
  Expect.equals(2, set.length);
  Expect.isTrue(set.contains(new EO(6)));
  Expect.isTrue(set.contains(new EO(8)));
}

// Objects that are equal based on data.
class EO {
  final int id;
  const EO(this.id);
  int get hashCode => id;
  bool operator==(Object other) => other is EO && id == (other as EO).id;
}

// Equality of Id objects based on id modulo value.
Function customEq(int mod) => (EO e1, EO e2) => ((e1.id - e2.id) % mod) == 0;
Function customHash(int mod) => (EO e) => e.id % mod;
bool validKey(Object o) => o is EO;


main() {
  testMain(() => new HashSet());
  testMain(() => new LinkedHashSet());
  testMain(() => new HashSet(equals: identical));
  testMain(() => new LinkedHashSet(equals: identical));
  testMain(() => new HashSet(equals: (a, b) => a == b,
                             hashCode: (a) => -a.hashCode,
                             isValidKey: (a) => true));
  testMain(() => new LinkedHashSet(
      equals: (a, b) => a == b,
      hashCode: (a) => -a.hashCode,
      isValidKey: (a) => true));

  testTypeAnnotations(new HashSet<int>());
  testTypeAnnotations(new LinkedHashSet<int>());
  testTypeAnnotations(new HashSet<int>(equals: identical));
  testTypeAnnotations(new LinkedHashSet<int>(equals: identical));
  testTypeAnnotations(new HashSet<int>(equals: (int a, int b) => a == b,
                                       hashCode: (int a) => a.hashCode,
                                       isValidKey: (a) => a is int));
  testTypeAnnotations(new LinkedHashSet<int>(equals: (int a, int b) => a == b,
                                             hashCode: (int a) => a.hashCode,
                                             isValidKey: (a) => a is int));

  testRetainWhere(([equals, hashCode, validKey]) =>
      new HashSet(equals: equals, hashCode: hashCode, isValidKey: validKey));
  testRetainWhere(([equals, hashCode, validKey]) =>
      new LinkedHashSet(equals: equals, hashCode: hashCode,
                        isValidKey: validKey));
}
