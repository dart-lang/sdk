// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import "dart:ffi";
import "dart:isolate";

import "callback_tests_utils.dart";

typedef Type = Int32 Function(Int32, Int32);
int unwindError(int x, int y) {
  print("unwindError($x, $y)");
  Isolate.current.kill(priority: Isolate.immediate);
  return x + y;
}

final testcases = [
  CallbackTest("UnwindError", Pointer.fromFunction<Type>(unwindError, 42)),
];

void child(_) {
  testcases.forEach((t) => t.run());
  throw "Should not be reached";
}

void main() {
  var onExit = new RawReceivePort();
  var onError = new RawReceivePort();
  onExit.handler = ((msg) {
    print("Child exited");
    onExit.close();
    onError.close();
  });
  onError.handler = ((msg) {
    throw "Child error: $msg";
  });
  Isolate.spawn(
    child,
    null,
    onError: onError.sendPort,
    onExit: onExit.sendPort,
  );
}
