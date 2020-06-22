// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--shared_slow_path_triggers_gc

import 'dart:typed_data';

import 'package:expect/expect.dart';

Uint8List l = int.parse('1') == 1 ? Uint8List(10) : Uint8List(0);
final int outOfRangeSmi = int.parse('-1');
final int outOfRangeSmi2 = int.parse('10');
final int outOfRangeMint = int.parse('${0x7fffffffffffffff}');
final int outOfRangeMint2 = int.parse('${0x8000000000000000}');

buildErrorMatcher(int outOfRangeValue) {
  return (error) {
    return error is RangeError &&
        error.start == 0 &&
        error.end == 9 &&
        error.invalidValue == outOfRangeValue;
  };
}

main() {
  for (int i = 0; i < 10; ++i) l[i] = i;

  Expect.throws(() => l[outOfRangeSmi], buildErrorMatcher(outOfRangeSmi));
  Expect.throws(() => l[outOfRangeSmi2], buildErrorMatcher(outOfRangeSmi2));
  Expect.throws(() => l[outOfRangeMint], buildErrorMatcher(outOfRangeMint));
  Expect.throws(() => l[outOfRangeMint2], buildErrorMatcher(outOfRangeMint2));

  if (int.parse('1') == 0) l = Uint8List(0);
  for (int i = 0; i < 10; ++i) {
    Expect.equals(i, l[i]);
  }
}
