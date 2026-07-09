// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Since dynamic downcasts can fail, their evaluation order is observable. This
// test verifies that in an invocation with multiple arguments, each argument is
// evaluated and then (if necessary) downcast prior to evaluating the next
// argument.

// The test pays special attention to the situation where a named argument
// precedes a positional argument, since the front end is known to re-order such
// arguments when converting to the kernel representation.

// This test only makes sense to run on platforms that check implicit downcasts.
// Requirements=checked-implicit-downcasts

import 'package:expect/expect.dart';

final List<String> log = [];

void f(int x, int y) {
  log.add('f($x, $y) called');
}

void g(int x, {required int y}) {
  log.add('g($x, y: $y) called');
}

void h({required int x, required int y}) {
  log.add('h(x: $x, y: $y) called');
}

T compute<T>(T t) {
  log.add('computed $t');
  return t;
}

void testTwoPositionalArgs() {
  log.clear();
  Expect.throws<TypeError>(() => f(compute<dynamic>('bad'), compute<int>(1)));
  Expect.listEquals(['computed bad'], log);

  log.clear();
  Expect.throws<TypeError>(() => f(compute<int>(0), compute<dynamic>('bad')));
  Expect.listEquals(['computed 0', 'computed bad'], log);

  log.clear();
  f(compute<int>(0), compute<int>(1));
  Expect.listEquals(['computed 0', 'computed 1', 'f(0, 1) called'], log);
}

void testPositionalThenNamedArg() {
  log.clear();
  Expect.throws<TypeError>(
    () => g(compute<dynamic>('bad'), y: compute<int>(1)),
  );
  Expect.listEquals(['computed bad'], log);

  log.clear();
  Expect.throws<TypeError>(
    () => g(compute<int>(0), y: compute<dynamic>('bad')),
  );
  Expect.listEquals(['computed 0', 'computed bad'], log);

  log.clear();
  g(compute<int>(0), y: compute<int>(1));
  Expect.listEquals(['computed 0', 'computed 1', 'g(0, y: 1) called'], log);
}

void testNamedThenPositionalArg() {
  log.clear();
  Expect.throws<TypeError>(
    () => g(y: compute<dynamic>('bad'), compute<int>(1)),
  );
  Expect.listEquals(['computed bad'], log);

  log.clear();
  Expect.throws<TypeError>(
    () => g(y: compute<int>(0), compute<dynamic>('bad')),
  );
  Expect.listEquals(['computed 0', 'computed bad'], log);

  log.clear();
  g(y: compute<int>(0), compute<int>(1));
  Expect.listEquals(['computed 0', 'computed 1', 'g(1, y: 0) called'], log);
}

void testTwoNamedArgsInOrder() {
  log.clear();
  Expect.throws<TypeError>(
    () => h(x: compute<dynamic>('bad'), y: compute<int>(1)),
  );
  Expect.listEquals(['computed bad'], log);

  log.clear();
  Expect.throws<TypeError>(
    () => h(x: compute<int>(0), y: compute<dynamic>('bad')),
  );
  Expect.listEquals(['computed 0', 'computed bad'], log);

  log.clear();
  h(x: compute<int>(0), y: compute<int>(1));
  Expect.listEquals(['computed 0', 'computed 1', 'h(x: 0, y: 1) called'], log);
}

void testTwoNamedArgsOutOfOrder() {
  log.clear();
  Expect.throws<TypeError>(
    () => h(y: compute<dynamic>('bad'), x: compute<int>(1)),
  );
  Expect.listEquals(['computed bad'], log);

  log.clear();
  Expect.throws<TypeError>(
    () => h(y: compute<int>(0), x: compute<dynamic>('bad')),
  );
  Expect.listEquals(['computed 0', 'computed bad'], log);

  log.clear();
  h(y: compute<int>(0), x: compute<int>(1));
  Expect.listEquals(['computed 0', 'computed 1', 'h(x: 1, y: 0) called'], log);
}

void main() {
  testTwoPositionalArgs();
  testPositionalThenNamedArg();
  testNamedThenPositionalArg();
  testTwoNamedArgsInOrder();
  testTwoNamedArgsOutOfOrder();
}
