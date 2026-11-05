// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from
//   LanguageFeatures/Patterns/execution_pattern_for_element_A01_t05.dart

class Square(final double length) {
  double get areaAsDouble => length * length;
  int get areaAsInt => areaAsDouble.toInt();
}

main() {
  var list = [
    0,
    for (
      var Square(:areaAsInt) = Square(1);
      areaAsInt <= 9;
      Square(:areaAsInt) = Square((++areaAsInt).toDouble())
    )
      areaAsInt,
    42,
  ];
  expect([0, 1, 4, 42], list);
}

expect<T>(List<T> expected, List<T> actual) {
  if (expected.length != actual.length) {
    throw 'Length mismatch: Expected $expected of length '
        '${expected.length}. Actual $actual of length ${actual.length}.';
  }
  for (int i = 0; i < expected.length; i++) {
    if (expected[i] != actual[i]) {
      throw 'Expected ${expected[i]}, actual ${actual[i]} at index $i';
    }
  }
}
