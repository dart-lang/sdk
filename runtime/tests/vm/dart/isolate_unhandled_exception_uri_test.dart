// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_unhandled_exception_uri_helper;

import 'dart:isolate';

// Tests that isolate code in another script keeps message handling working
// after throwing an unhandled exception, if it has a function called
// unhandledExceptionCallback that returns true (continue handling).

// Note: this test will hang if an uncaught exception isn't handled,
// either by an error in the callback or it returning false.

void main() {
  var isolate_port = spawnUri('isolate_unhandled_exception_uri_helper.dart');

  // Send a message that will cause an ignorable exception to be thrown.
  Future f = isolate_port.call('throw exception');
  f.onComplete((future) {
    Expect.equals(null, future.exception);
  });

  // Verify that isolate can still handle messages.
  isolate_port.call('hi').onComplete((future) {
    Expect.equals(null, future.exception);
    Expect.equals('hello', future.value);
  });

}
