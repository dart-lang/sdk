// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_unhandled_exception_test;

import 'dart:async';
import 'dart:isolate';

// Tests that an isolate's keeps message handling working after
// throwing an unhandled exception, if it was created with an
// unhandled exception callback that returns true (continue handling).
// This test verifies that a callback function specified in
// Isolate.spawnFunction is called.

// Note: this test will hang if an uncaught exception isn't handled,
// either by an error in the callback or it returning false.

void entry() {
  port.receive((message, replyTo) {
    if (message == 'throw exception') {
      replyTo.call('throwing exception');
      throw new RuntimeError('ignore this exception');
    }
    replyTo.call('hello');
    port.close();
  });
}

bool exceptionCallback(IsolateUnhandledException e) {
  return e.source.message == 'ignore this exception';
}

void main() {
  var isolate_port = spawnFunction(entry, exceptionCallback);

  // Send a message that will cause an ignorable exception to be thrown.
  Future f = isolate_port.call('throw exception');
  f.catchError((error) {
    // Exception wasn't ignored as it was supposed to be.
    Expect.fail("Error not expected");
  });

  // Verify that isolate can still handle messages.
  isolate_port.call('hi').then((value) {
    Expect.equals('hello', value);
  }, onError: (error) {
    Expect.fail("Error not expected");
  });
}
