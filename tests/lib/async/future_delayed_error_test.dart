// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_delayed_error_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

testImmediateError() {
  // An open ReceivePort keeps the VM running. If the error-handler below is not
  // executed then the test will fail with a timeout.
  var port = new ReceivePort();
  var future = new Future.error("error");
  future.catchError((error) {
    port.close();
    Expect.equals(error, "error");
  });
}

Future get completedFuture {
  var completer = new Completer();
  completer.completeError("foobar");
  return completer.future;
}

testDelayedError() {
  var port = new ReceivePort();
  completedFuture.catchError((error) {
    port.close();
    Expect.equals(error, "foobar");
  });
}

main() {
  testImmediateError();
  testDelayedError();
}

