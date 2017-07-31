// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testEmpty(name, Iterable<int> it, [depth = 2]) {
    Expect.isTrue(it.isEmpty, name);
    Expect.isFalse(it.isNotEmpty, name);
    Expect.equals(0, it.length, name);
    Expect.isFalse(it.contains(null), name);
    Expect.isFalse(it.any((x) => true), name);
    Expect.isTrue(it.every((x) => false), name);
    Expect.throws(() => it.first, (e) => e is StateError, name);
    Expect.throws(() => it.last, (e) => e is StateError, name);
    Expect.throws(() => it.single, (e) => e is StateError, name);
    Expect.throws(() => it.elementAt(0), (e) => e is RangeError, name);
    Expect.throws(() => it.reduce((a, b) => a), (e) => e is StateError, name);
    Expect.throws(
        () => it.singleWhere((_) => true), (e) => e is StateError, name);
    Expect.equals(42, it.fold(42, (a, b) => "not 42"), name);
    Expect.equals(42, it.firstWhere((v) => true, orElse: () => 42), name);
    Expect.equals(42, it.lastWhere((v) => true, orElse: () => 42), name);
    Expect.equals("", it.join("separator"), name);
    Expect.equals("()", it.toString(), name);
    Expect.listEquals([], it.toList(), name);
    Expect.listEquals([], it.toList(growable: false), name);
    Expect.listEquals([], it.toList(growable: true), name);
    Expect.equals(0, it.toSet().length, name);
    // Doesn't throw:
    it.forEach((v) => throw v);
    for (var v in it) {
      throw v;
    }
    // Check that returned iterables are also empty.
    if (depth > 0) {
      testEmpty("$name-map", it.map((x) => x), depth - 1);
      testEmpty("$name-where", it.where((x) => true), depth - 1);
      testEmpty("$name-expand", it.expand((x) => [x]), depth - 1);
      testEmpty("$name-skip", it.skip(1), depth - 1);
      testEmpty("$name-take", it.take(2), depth - 1);
      testEmpty("$name-skipWhile", it.skipWhile((v) => false), depth - 1);
      testEmpty("$name-takeWhile", it.takeWhile((v) => true), depth - 1);
    }
  }

  testType(name, it, [depth = 2]) {
    Expect.isTrue(it is Iterable<int>, name);
    Expect.isFalse(it is Iterable<String>, name);
    if (depth > 0) {
      testType("$name-where", it.where((_) => true), depth - 1);
      testType("$name-skip", it.skip(1), depth - 1);
      testType("$name-take", it.take(1), depth - 1);
      testType("$name-skipWhile", it.skipWhile((_) => false), depth - 1);
      testType("$name-takeWhile", it.takeWhile((_) => true), depth - 1);
      testType("$name-toList", it.toList(), depth - 1);
      testType("$name-toList", it.toList(growable: false), depth - 1);
      testType("$name-toList", it.toList(growable: true), depth - 1);
      testType("$name-toSet", it.toSet(), depth - 1);
    }
  }

  test(name, it) {
    testEmpty(name, it);
    testType(name, it);
  }

  test("const", const Iterable<int>.empty());
  test("new", new Iterable<int>.empty());
}
