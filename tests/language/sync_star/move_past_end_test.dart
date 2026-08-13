// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test program for sync* generator functions that have their iterator moved
// past the end. Moving past the end should not cause re-execution of parts of
// the generator.

import "package:expect/expect.dart";

String log = '';

Iterable<int> simpleGenerator() sync* {
  log += 'a';
  yield 1;
  log += 'b';
  yield 2;
  log += 'c';
}

Iterable<int> compoundGenerator() sync* {
  log += 'X';
  yield* simpleGenerator();
  log += 'Y';
  yield* simpleGenerator();
  log += 'Z';
}

void testSimple() {
  log = '';
  Expect.equals('12', simpleGenerator().join());
  Expect.equals('abc', log);

  log = '';
  final iterator = simpleGenerator().iterator;
  Expect.isTrue(iterator.moveNext());
  Expect.isTrue(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.equals('abc', log);
}

void testCompound() {
  log = '';
  Expect.equals('1212', compoundGenerator().join());
  Expect.equals('XabcYabcZ', log);

  log = '';
  final iterator = compoundGenerator().iterator;
  Expect.isTrue(iterator.moveNext());
  Expect.isTrue(iterator.moveNext());
  Expect.isTrue(iterator.moveNext());
  Expect.isTrue(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.isFalse(iterator.moveNext());
  Expect.equals('XabcYabcZ', log);
}

void main() {
  for (final test in [testSimple, testCompound]) {
    test();
  }
}
