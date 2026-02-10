// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=record-spreads

/// Test that spread expressions are evaluated exactly once and in the correct
/// order.

import "package:expect/expect.dart";

List<String> log = [];

(int, int) makePoint() {
  log.add('makePoint');
  return (1, 2);
}

(int, int) makePoint2() {
  log.add('makePoint2');
  return (3, 4);
}

({String color}) makeStyle() {
  log.add('makeStyle');
  return (color: 'red');
}

int sideEffect(String label, int value) {
  log.add(label);
  return value;
}

void main() {
  // Spread expression evaluated exactly once.
  log.clear();
  var r1 = (...makePoint(), 3);
  Expect.equals(1, r1.$1);
  Expect.equals(2, r1.$2);
  Expect.equals(3, r1.$3);
  Expect.listEquals(['makePoint'], log);

  // Multiple spreads evaluated left to right.
  log.clear();
  var r2 = (...makePoint(), ...makePoint2());
  Expect.equals(1, r2.$1);
  Expect.equals(2, r2.$2);
  Expect.equals(3, r2.$3);
  Expect.equals(4, r2.$4);
  Expect.listEquals(['makePoint', 'makePoint2'], log);

  // Spread and non-spread fields evaluated in order.
  log.clear();
  var r3 = (sideEffect('a', 10), ...makePoint(), sideEffect('b', 30));
  Expect.equals(10, r3.$1);
  Expect.equals(1, r3.$2);
  Expect.equals(2, r3.$3);
  Expect.equals(30, r3.$4);
  Expect.listEquals(['a', 'makePoint', 'b'], log);

  // Named spread fields and positional fields evaluated in order.
  log.clear();
  var r4 = (sideEffect('first', 1), ...makeStyle(), sideEffect('last', 2));
  Expect.equals(1, r4.$1);
  Expect.equals('red', r4.color);
  Expect.equals(2, r4.$2);
  Expect.listEquals(['first', 'makeStyle', 'last'], log);
}
