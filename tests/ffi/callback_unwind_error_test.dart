// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import "dart:ffi";
import "dart:isolate";

import "callback_tests_utils.dart";

typedef SimpleAdditionType = Int32 Function(Int32, Int32);
int simpleAddition(int x, int y) {
  print("simpleAddition($x, $y)");
  Isolate.current.kill(priority: Isolate.immediate);
  return x + y;
}

final testcases = [
  CallbackTest("SimpleAddition",
      Pointer.fromFunction<SimpleAdditionType>(simpleAddition, 0)),
];

void main() {
  testcases.forEach((t) => t.run());
  throw "Should not be reached";
}
