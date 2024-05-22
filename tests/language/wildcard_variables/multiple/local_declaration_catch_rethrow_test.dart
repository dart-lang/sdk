// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple catch clause wildcard variable declarations with rethrow.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

void main() {
  var error = StateError("State bad!");
  var stack = StackTrace.fromString("My stack trace");
  var caught = false;

  // Multiple wildcard catch clause variables.
  try {
    try {
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_, _) {
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
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_) {
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
      Error.throwWithStackTrace(error, stack);
    } on StateError catch (_, s) {
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
