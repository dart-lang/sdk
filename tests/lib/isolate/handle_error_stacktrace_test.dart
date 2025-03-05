// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library handle_error_stacktrace_test;

import "dart:isolate";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

const errorValue = "TEST_ERROR";
const stackTraceValue = "TEST_STACKTRACE";

void isolateMain() {
  Error.throwWithStackTrace(errorValue, StackTrace.fromString(stackTraceValue));
}

void main() async {
  asyncStart();

  var receivedErrors = 0;
  final errorPort = ReceivePort();
  errorPort.listen((errorAndStack) {
    Expect.listEquals([errorValue, stackTraceValue], errorAndStack);
    receivedErrors++;

    if (receivedErrors == 2) {
      errorPort.close();
      asyncEnd();
    }
  });

  Isolate.spawn((_) => isolateMain(), null, onError: errorPort.sendPort);
  Isolate.spawn(
    (_) => isolateMain(),
    null,
    onError: errorPort.sendPort,
    errorsAreFatal: false,
  );
}
