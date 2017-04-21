// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

StackTrace captureStackTrace() {
  try {
    throw 0;
  } catch (e, st) {
    return st;
  }
}

main() {
  Completer completer = new Completer();
  StackTrace trace = captureStackTrace();
  StackTrace whenCompleteStackTrace;
  asyncStart();
  completer.future.whenComplete(() {
    throw "other_error";
  }).then((_) {
    throw "should never be reached";
  }).catchError((e, st) {
    Expect.equals("other_error", e);
    Expect.isNotNull(st);
    Expect.isFalse(identical(trace, st));
    whenCompleteStackTrace = st;
    // Test the rethrowing the same error keeps the stack trace.
    throw e;
  }).catchError((e, st) {
    Expect.equals("other_error", e);
    Expect.identical(whenCompleteStackTrace, st);
    asyncEnd();
  });
  completer.completeError("c-error", trace);
}
