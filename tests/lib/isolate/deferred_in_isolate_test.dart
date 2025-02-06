// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deferred libraries are supported from isolates other than the root
// isolate.

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() {
  asyncStart(4);
  var receivePort = RawReceivePort();
  var nonce = "Deferred Loaded.";
  int state = 0; // Incremented when reaching expected steps in communication.

  receivePort.handler = (reply) {
    if (reply == null) {
      Expect.equals(2, state); // After isolate result message.
      state = -1;
      // Isolate exit.
      receivePort.close();
      asyncEnd();
    } else if (reply == true) {
      Expect.equals(0, state); // Initial isolate-start message.
      state = 1;
      asyncEnd();
    } else if (reply case [String error, String stack]) {
      // Isolate unhandled or handled error.
      var remoteError = RemoteError("@$state: $error", stack);
      Error.throwWithStackTrace(remoteError, remoteError.stackTrace);
    } else {
      Expect.equals("*$nonce*", reply);
      Expect.equals(1, state); // After isolate-start message.
      state = 2;
      asyncEnd();
    }
  };

  Isolate.spawnUri(
    Uri(path: 'deferred_in_isolate_app.dart'),
    [nonce],
    receivePort.sendPort,
    onError: receivePort.sendPort,
    onExit: receivePort.sendPort,
  ).then((_) {
    asyncEnd();
  });
}
