// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'catch_errors.dart';

main() {
  asyncStart();
  Completer done = new Completer();

  // Make sure that the zones use the scheduleMicrotask of their zones.
  int scheduleMicrotaskCount = 0;
  Completer completer;
  Completer completer2;
  Future future;
  Future future2;
  runZonedScheduleMicrotask(() {
    completer = new Completer();
    completer.complete(499);
    completer2 = new Completer.sync();
    completer2.complete(-499);
    future = new Future.value(42);
    future2 = new Future.error(11);
  }, onScheduleMicrotask: (f) {
    scheduleMicrotaskCount++;
    scheduleMicrotask(f);
  });
  int openCallbackCount = 0;

  openCallbackCount++;
  completer.future.then((x) {
    Expect.equals(499, x);
    openCallbackCount--;
    if (openCallbackCount == 0) done.complete();
  });

  openCallbackCount++;
  completer2.future.then((x) {
    Expect.equals(-499, x);
    openCallbackCount--;
    if (openCallbackCount == 0) done.complete();
  });

  openCallbackCount++;
  future.then((x) {
    Expect.equals(42, x);
    openCallbackCount--;
    if (openCallbackCount == 0) done.complete();
  });

  openCallbackCount++;
  future2.catchError((x) {
    Expect.equals(11, x);
    openCallbackCount--;
    if (openCallbackCount == 0) done.complete();
  });

  done.future.whenComplete(() {
    Expect.equals(4, scheduleMicrotaskCount);
    asyncEnd();
  });
}
