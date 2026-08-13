// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-asserts

import 'package:expect/expect.dart';

void main() {
  try {
    assert(false, "failure message");
  } on AssertionError catch (error) {
    var message = error.toString();
    Expect.contains('Assertion failed:', message);
    Expect.contains('assertion_failure_message_test.dart:11:5', message);
    Expect.contains('false', message);
    Expect.contains('failure message', message);
  }

  // 失 All offsets and source code extractions should still be correct after
  // non-UTF8 characters.
  try {
    assert(false, "after a non-UTF8 character");
  } on AssertionError catch (error) {
    var message = error.toString();
    Expect.contains('Assertion failed:', message);
    Expect.contains('assertion_failure_message_test.dart:23:5', message);
    Expect.contains('false', message);
    Expect.contains('after a non-UTF8 character', message);
  }
}
