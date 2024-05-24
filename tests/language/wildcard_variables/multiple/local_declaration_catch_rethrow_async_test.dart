// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple catch clause wildcard variable declarations with rethrow and
// awaits.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

void main() async {
  asyncStart();
  test().then((_) => asyncEnd());
}

Future<void> test() async {
  var tryValue = Future<int>.value(1);
  var catchValue = Future<int>.value(1);

  var error = StateError("State bad!");
  var stack = StackTrace.fromString("My stack trace");
  var caught = false;

  // Multiple wildcard catch clause variables.
  try {
    try {
      await tryValue;
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_, _) {
      await catchValue;
      caught = true;
      rethrow;
    }
  } on StateError catch (e, s) {
    Expect.isTrue(caught);
    Expect.identical(error, e);
    Expect.equals(stack.toString(), s.toString());
    Expect.equals(stack.toString(), e.stackTrace.toString());
  }

  // Single wildcard catch clause variable.
  try {
    try {
      await tryValue;
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_) {
      await catchValue;
      caught = true;
      rethrow;
    }
  } on StateError catch (e, s) {
    Expect.isTrue(caught);
    Expect.identical(error, e);
    Expect.equals(stack.toString(), s.toString());
    Expect.equals(stack.toString(), e.stackTrace.toString());
  }

  try {
    try {
      await tryValue;
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_, s) {
      await catchValue;
      Expect.equals(stack.toString(), s.toString());
      caught = true;
      rethrow;
    }
  } on StateError catch (e, s) {
    Expect.isTrue(caught);
    Expect.identical(error, e);
    Expect.equals(stack.toString(), s.toString());
    Expect.equals(stack.toString(), e.stackTrace.toString());
  }
}
