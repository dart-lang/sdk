// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import 'dart:async';

var events = [];
var delayedValue = new Completer();
var delayedError = new Completer();

foo() async {
  new Future.microtask(() => 'in microtask')
      .then(events.add)
      .then(delayedValue.complete);
  return 'in async function';
}

bar() async {
  new Future.microtask(() => throw 'in microtask error')
      .catchError(events.add)
      .then(delayedError.complete);
  throw 'in async function error';
}

void main() {
  asyncStart();
  var asyncValueFuture = foo().then(events.add);
  var asyncErrorFuture = bar().catchError(events.add);
  Future.wait([
    asyncValueFuture,
    delayedValue.future,
    asyncErrorFuture,
    delayedError.future
  ]).then((_) {
    // The body completed before nested microtask. So they should appear
    // before the delayed functions. In other words, the async function should
    // not unnecessarily delay the propagation of errors and values.
    Expect.listEquals([
      "in async function",
      "in async function error",
      "in microtask",
      "in microtask error"
    ], events);
    asyncEnd();
  });
}
