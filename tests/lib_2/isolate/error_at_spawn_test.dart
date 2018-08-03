// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_at_spawn;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

isomain(args) {
  throw new ArgumentError("fast error");
}

main() {
  asyncStart();

  // Capture errors from other isolate as raw messages.
  RawReceivePort errorPort = new RawReceivePort();
  errorPort.handler = (message) {
    String error = message[0];
    String stack = message[1];
    Expect.equals(new ArgumentError("fast error").toString(), "$error");
    errorPort.close();
    asyncEnd();
  };

  Isolate.spawn(isomain, null,
      // Setup handler as part of spawn.
      errorsAreFatal: false,
      onError: errorPort.sendPort);
}
