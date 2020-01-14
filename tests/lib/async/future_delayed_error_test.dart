// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_delayed_error_test;

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

testImmediateError() {
  asyncStart();
  var future = new Future.error("error");
  future.catchError((error) {
    Expect.equals(error, "error");
    asyncEnd();
  });
}

Future get completedFuture {
  var completer = new Completer();
  completer.completeError("foobar");
  return completer.future;
}

testDelayedError() {
  asyncStart();
  completedFuture.catchError((error) {
    Expect.equals(error, "foobar");
    asyncEnd();
  });
}

main() {
  testImmediateError();
  testDelayedError();
}
