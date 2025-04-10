// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import "dart:ffi";
import "dart:isolate";

import "dylib_utils.dart";

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

Object unwindErrorThroughHandle(int x, int y) {
  print("unwindErrorThroughHandle($x, $y)");
  Isolate.current.kill(priority: Isolate.immediate);
  return x + y;
}

typedef CallbackType = Handle Function(Int32, Int32);
typedef CalloutCType = Handle Function(Pointer);
typedef CalloutDartType = Object Function(Pointer);

void child(_) {
  final callout = ffiTestFunctions
      .lookupFunction<CalloutCType, CalloutDartType>(
        "TestUnwindErrorThroughHandle",
        isLeaf: false,
      );
  final callback = Pointer.fromFunction<CallbackType>(unwindErrorThroughHandle);
  callout(callback);
  throw "Should not be reached";
}

void main() {
  final onExit = new RawReceivePort();
  final onError = new RawReceivePort();
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
