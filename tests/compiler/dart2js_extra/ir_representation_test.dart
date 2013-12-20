// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The multitest framework does not support import paths that contain '..',
// therefore it's not used in this file.
import '../dart2js_native/compiler_test_internals.dart';

/**
 * This test verifies that the @IrRepresentation annotation works as expected.
 * It might fail when extending the IR to express more of Dart.
 */

// closure
@IrRepresentation(true)
test1() {
  var f = () => 42;
  return 1;
}

// parameter
@IrRepresentation(true)
test2(x) {
  return x;
}

// dynamic invocation, construction
@IrRepresentation(true)
test3() {
  new Object().hashCode;
}

// exceptions
@IrRepresentation(true)
test4() {
  try {
    throw "possum";
  } catch (e) {
    return e;
  }
}

// control flow, loops
@IrRepresentation(true)
test5(x) {
  while (x < 100) {
    x += x;
  }
  if (x % 2 == 0) {
    return 1;
  } else {
    return 2;
  }
}

main() {
  print(test1());
  print(test2(1));
  print(test3());
  print(test4());
  print(test5(2));
}
