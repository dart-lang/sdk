// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

main() {
  testIterableApi();
  testUnmodifiableSetApi();
  testMutatingApisThrow();
  testChangesInOriginalSetAreObservedInUnmodifiableView();
}

void testIterableApi() {
  Set<int> original = {1, 2, 3};
  Set<int> copy = {...original};
  UnmodifiableSetView<int> wrapped = new UnmodifiableSetView(original);

  Expect.equals(wrapped.any((_) => true), original.any((_) => true));
  Expect.equals(wrapped.any((_) => false), original.any((_) => false));

  Expect.equals(wrapped.contains(0), original.contains(0));
  Expect.equals(wrapped.elementAt(0), original.elementAt(0));

  Expect.equals(wrapped.every((_) => true), original.every((_) => true));
  Expect.equals(wrapped.every((_) => false), original.every((_) => false));

  Expect.setEquals(
      wrapped.expand((x) => [x, x]), original.expand((x) => [x, x]));

  Expect.equals(wrapped.first, original.first);

  Expect.equals(
      wrapped.firstWhere((_) => true), original.firstWhere((_) => true));
  Expect.throwsStateError(() {
    wrapped.firstWhere((_) => false);
  }, "firstWhere");

  Expect.equals(wrapped.fold<int>(0, (x, y) => x + y),
      original.fold<int>(0, (x, y) => x + y));

  testForeach(wrapped, original);

  Expect.equals(wrapped.isEmpty, original.isEmpty);

  Expect.equals(wrapped.isNotEmpty, original.isNotEmpty);

  testIterator(wrapped, original);

  Expect.equals(wrapped.join(""), original.join(""));
  Expect.equals(wrapped.join("-"), original.join("-"));

  Expect.equals(wrapped.last, original.last);

  Expect.equals(
      wrapped.lastWhere((_) => true), original.lastWhere((_) => true));
  Expect.throwsStateError(() {
    wrapped.lastWhere((_) => false);
  }, "lastWhere");

  Expect.equals(wrapped.length, original.length);

  Expect.setEquals(wrapped.map((x) => "[$x]"), original.map((x) => "[$x]"));

  Expect.equals(
      wrapped.reduce((x, y) => x + y), original.reduce((x, y) => x + y));

  Expect.throwsStateError(() {
    wrapped.single;
  }, "single");

  Expect.throwsStateError(() {
    wrapped.singleWhere((_) => true);
  }, "singleWhere true");
  Expect.throwsStateError(() {
    wrapped.singleWhere((_) => false);
  }, "singleWhere false");

  Expect.setEquals(wrapped.skip(0), original.skip(0));
  Expect.setEquals(wrapped.skip(1), original.skip(1));

  Expect.setEquals(
      wrapped.skipWhile((_) => true), original.skipWhile((_) => true));
  Expect.setEquals(
      wrapped.skipWhile((_) => false), original.skipWhile((_) => false));

  Expect.setEquals(wrapped.take(0), original.take(0));
  Expect.setEquals(wrapped.take(1), original.take(1));

  Expect.setEquals(
      wrapped.takeWhile((_) => true), original.takeWhile((_) => true));
  Expect.setEquals(
      wrapped.takeWhile((_) => false), original.takeWhile((_) => false));

  var toListResult = wrapped.toList();
  Expect.listEquals(original.toList(), toListResult);
  toListResult.add(4);
  Expect.listEquals([1, 2, 3, 4], toListResult);
  toListResult[3] = 5;
  Expect.listEquals([1, 2, 3, 5], toListResult);
  // wrapped and original are intact
  Expect.setEquals(copy, wrapped);
  Expect.setEquals(copy, original);

  var toSetResult = wrapped.toSet();
  Expect.setEquals(original.toSet(), toSetResult);
  toSetResult.add(4);
  Expect.setEquals({1, 2, 3, 4}, toSetResult);
  // wrapped and original are intact
  Expect.setEquals(copy, wrapped);
  Expect.setEquals(copy, original);

  Expect.setEquals(wrapped.where((_) => true), original.where((_) => true));
  Expect.setEquals(wrapped.where((_) => false), original.where((_) => false));
}

void testUnmodifiableSetApi() {
  Set<int> original = {1, 2, 3};
  Set<int> copy = {...original};
  UnmodifiableSetView<int> wrapped = new UnmodifiableSetView(original);

  Expect.isTrue(wrapped.containsAll(copy));
  Expect.isTrue(wrapped.containsAll(copy.toList()));
  Expect.isTrue(wrapped.containsAll([]));

  Expect.isTrue(wrapped.intersection({}).isEmpty);
  Expect.setEquals(wrapped.intersection(copy), original);

  Expect.setEquals(wrapped.union({}), original);
  Expect.setEquals(wrapped.union(copy), original);

  Expect.setEquals(wrapped.difference({}), original);
  Expect.isTrue(wrapped.difference(copy).isEmpty);
}

void testMutatingApisThrow() {
  UnmodifiableSetView<int> s = new UnmodifiableSetView({1, 2, 3});

  Expect.throwsUnsupportedError(() {
    s.add(3);
  }, "add");

  Expect.throwsUnsupportedError(() {
    s.addAll({1, 2, 3});
  }, "addAll");

  Expect.throwsUnsupportedError(() {
    s.addAll(<int>{});
  }, "addAll empty");

  Expect.throwsUnsupportedError(() {
    s.remove(3);
  }, "remove");

  Expect.throwsUnsupportedError(() {
    s.removeAll({1, 2, 3});
  }, "removeAll");

  Expect.throwsUnsupportedError(() {
    s.removeAll(<int>{});
  }, "removeAll empty");

  Expect.throwsUnsupportedError(() {
    s.retainAll({1, 2, 3});
  }, "retainAll");

  Expect.throwsUnsupportedError(() {
    s.retainAll(<int>{});
  }, "retainAll empty");

  Expect.throwsUnsupportedError(() {
    s.removeWhere((_) => true);
  }, "removeWhere");

  Expect.throwsUnsupportedError(() {
    s.retainWhere((_) => false);
  }, "retainWhere");

  Expect.throwsUnsupportedError(() {
    s.clear();
  }, "clear");
}

void testChangesInOriginalSetAreObservedInUnmodifiableView() {
  Set<int> original = {1, 2, 3};
  Set<int> copy = {...original};
  UnmodifiableSetView<int> wrapped = new UnmodifiableSetView(original);

  original.add(4);
  Expect.setEquals(original, wrapped);
  Expect.setEquals({4}, wrapped.difference(copy));
}

void testForeach(Set<int> wrapped, Set<int> original) {
  var wrapCtr = 0;
  var origCtr = 0;

  wrapped.forEach((x) {
    wrapCtr += x;
  });

  original.forEach((x) {
    origCtr += x;
  });

  Expect.equals(wrapCtr, origCtr);
}

void testIterator(Set<int> wrapped, Set<int> original) {
  Iterator wrapIter = wrapped.iterator;
  Iterator origIter = original.iterator;

  while (origIter.moveNext()) {
    Expect.isTrue(wrapIter.moveNext());
    Expect.equals(wrapIter.current, origIter.current);
  }

  Expect.isFalse(wrapIter.moveNext());
}
