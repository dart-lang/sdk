// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

f_1_1_no_default(a, [b]) => a + b;

f_1_1_default(a, [b = 2]) => a + b;

f_1_b_no_default(a, {b}) => a + b;

f_1_b_default(a, {b: 2}) => a + b;

test_1_1(Function f, bool hasDefault) {
  var result = f(40, 2);
  if (42 != result) throw "Unexpected result: $result";
  test_1(f, hasDefault);
}

test_1_b(Function f, bool hasDefault) {
  var result = f(40, b: 2);
  if (42 != result) throw "Unexpected result: $result";
  test_1(f, hasDefault);
}

test_1(Function f, bool hasDefault) {
  var result = 0;
  bool threw = true;
  try {
    result = f(40);
    threw = false;
  } catch (_) {
    // Ignored.
  }
  if (hasDefault) {
    if (threw) throw "Unexpected exception.";
    if (42 != result) throw "Unexpected result: $result.";
  } else {
    if (!threw) throw "Expected exception missing.";
    if (0 != result) throw "Unexpected result: $result.";
  }
}

main(arguments) {
  test_1_1(f_1_1_no_default, false);
  test_1_1(f_1_1_default, true);
  test_1_b(f_1_b_no_default, false);
  test_1_b(f_1_b_default, true);
}
