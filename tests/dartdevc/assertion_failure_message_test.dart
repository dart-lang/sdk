// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "utils.dart";

void main() {
  try {
    assert(false, "failure message");
  } on AssertionError catch (error) {
    var message = error.toString();
    expectStringContains('Assertion failed:', message);
    expectStringContains('assertion_failure_message_test.dart:9:12', message);
    expectStringContains('false', message);
    expectStringContains('failure message', message);
  }

  // 失 All offsets and source code extractions should still be correct after
  // non-UTF8 characters. See: https://github.com/dart-lang/sdk/issues/39271
  try {
    assert(false, "after a non-UTF8 character");
  } on AssertionError catch (error) {
    var message = error.toString();
    expectStringContains('Assertion failed:', message);
    expectStringContains('assertion_failure_message_test.dart:21:12', message);
    expectStringContains('false', message);
    expectStringContains('after a non-UTF8 character', message);
  }
}
