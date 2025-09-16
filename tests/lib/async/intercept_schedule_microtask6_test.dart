// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'catch_errors.dart';

class A {
  add(x) => print(x);
}

var events = [];

int body() {
  events.add("body entry");
  scheduleMicrotask(() {
    events.add("run async body");
    throw "foo";
  });
  return 499;
}

void onAsyncHandler(fun) {
  events.add("async handler");
  scheduleMicrotask(fun);
  events.add("async handler done");
}

void onErrorHandler(e) {
  events.add("error: $e");
}

void main() {
  asyncStart();

  // Test that runZonedScheduleMicrotask works when async, error and done
  // are used.
  var result = runZonedScheduleMicrotask(
    body,
    onScheduleMicrotask: onAsyncHandler,
    onError: onErrorHandler,
  );
  events.add("after");
  Timer.run(() {
    Expect.listEquals([
      "body entry",
      "async handler",
      "async handler done",
      "after",
      "run async body",
      "error: foo",
    ], events);
    asyncEnd();
  });
}
