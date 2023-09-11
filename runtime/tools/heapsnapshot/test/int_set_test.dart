// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:heapsnapshot/src/intset.dart';

main() {
  checkDump();
  checkBounds();
  handCodedTests();
  randomTests();

  print("OK");
}

void addExpectRangeError(set, int value) {
  try {
    set.add(value);
    throw "Expected RangeError";
  } on RangeError {
    // That's what we expect.
  }
}

void checkBounds() {
  SpecializedIntSet set = SpecializedIntSet(10);
  addExpectRangeError(set, -3);
  addExpectRangeError(set, -2);
  addExpectRangeError(set, -1);

  set.add(0);
  set.add(1);
  set.add(2);
  set.add(3);
  set.add(4);
  set.add(5);
  set.add(6);
  set.add(7);
  set.add(8);
  set.add(9);

  addExpectRangeError(set, 10);
  addExpectRangeError(set, 11);
  addExpectRangeError(set, 12);
}

void checkContainsOnly(Set<int> set, List<int> contains) {
  for (int i in contains) {
    if (!set.contains(i)) throw "Expected to contain '$i' but didn't.";
  }

  if (!set.containsAll(contains)) throw "Expected containsAll but didn't.";

  List<int> returned = [];
  for (int i in set) {
    returned.add(i);
  }

  returned.sort();
  contains.sort();

  checkLists(contains, returned);

  List<int> copy = set.toSet().toList();
  copy.sort();
  checkLists(contains, copy);

  if (identical(set, set.toSet())) throw "Expected toSet to give a new set";

  List<int> copy2 = set.toSet().union(set).toList();
  checkLists(contains, copy2);

  List<int> copy3 = set.toSet().intersection(set).toList();
  checkLists(contains, copy3);

  List<int> empty = set.toSet().difference(set).toList();
  if (empty.isNotEmpty) throw "Expected difference to be empty";
}

void checkDump() {
  SpecializedIntSet set = SpecializedIntSet(0);
  expectDump(set, "");
  set = SpecializedIntSet(1);
  expectDump(set, "00000000000000000000000000000000");
  set = SpecializedIntSet(32);
  expectDump(set, "00000000000000000000000000000000");
  set = SpecializedIntSet(33);
  expectDump(
      set, "00000000000000000000000000000000 00000000000000000000000000000000");
  set.add(0);
  expectDump(
      set, "10000000000000000000000000000000 00000000000000000000000000000000");
  set.add(8);
  expectDump(
      set, "10000000100000000000000000000000 00000000000000000000000000000000");
  set.addAll([2, 4, 6, 7, 8]);
  expectDump(
      set, "10101011100000000000000000000000 00000000000000000000000000000000");
  set.add(32);
  expectDump(
      set, "10101011100000000000000000000000 10000000000000000000000000000000");
}

void checkIsEmpty(Set<int> set) {
  if (set.length != 0) throw "Got a non-zero length.";
  for (int i in set) {
    throw "Iterated and got (at least) '$i', expected empty.";
  }
}

void checkLists(List<int> list1, List<int> list2) {
  if (list1.length != list2.length) {
    throw "Expected an iteration to give the same length but didn't.";
  }
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      throw "Expected an iteration to provide the same data but didn't.";
    }
  }
}

void expectDump(SpecializedIntSet set, String expected) {
  String returned = set.getDumpData();
  if (returned != expected) {
    throw "Expected '$expected' but got '$returned'";
  }
}

void handCodedTests() {
  const int maxExclusive = 42;
  Set<int> set = SpecializedIntSet(maxExclusive);

  List<int> expect = [32];
  setAddNew(set, 32);
  checkContainsOnly(set, expect);
  setAddExists(set, 32);
  checkContainsOnly(set, expect);

  for (int i = 0; i < maxExclusive; i++) {
    if (i == 32) continue;
    expect.add(i);
    setAddNew(set, i);
    checkContainsOnly(set, expect);
  }

  for (int i = 0; i < maxExclusive; i += 2) {
    expect.remove(i);
    setRemoveExists(set, i);
    setRemoveDoesntExists(set, i);
    checkContainsOnly(set, expect);
  }
  for (int i = 1; i < maxExclusive; i += 2) {
    expect.remove(i);
    setRemoveExists(set, i);
    setRemoveDoesntExists(set, i);
    checkContainsOnly(set, expect);
  }
  checkIsEmpty(set);
}

void randomTests() {
  int seed = Random.secure().nextInt(10000);
  print("Using seed $seed");
  Random r = new Random(seed);
  List<int> expect = [];
  const int maxExclusive = 100;
  Set<int> set = SpecializedIntSet(maxExclusive);
  for (int j = 0; j < 1000; j++) {
    for (int i = 0; i < 20; i++) {
      int value = r.nextInt(maxExclusive);
      if (expect.contains(value)) {
        setAddExists(set, value);
      } else {
        setAddNew(set, value);
        expect.add(value);
      }
      checkContainsOnly(set, expect);
    }
    for (int i = 0; i < 20; i++) {
      int value = r.nextInt(maxExclusive);
      if (expect.contains(value)) {
        setRemoveExists(set, value);
        expect.remove(value);
      } else {
        setRemoveDoesntExists(set, value);
      }
      checkContainsOnly(set, expect);
    }
  }
}

void setAddExists(Set<int> set, int value) {
  if (set.add(value)) throw "Expected false";
}

void setAddNew(Set<int> set, int value) {
  if (!set.add(value)) throw "Expected true";
}

void setRemoveDoesntExists(Set<int> set, int value) {
  if (set.remove(value)) throw "Expected false";
}

void setRemoveExists(Set<int> set, int value) {
  if (!set.remove(value)) throw "Expected true";
}
