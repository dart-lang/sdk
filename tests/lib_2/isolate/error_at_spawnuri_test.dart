// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherScripts=error_at_spawnuri_iso.dart

library error_at_spawnuri;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

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

  Isolate.spawnUri(Uri.parse("error_at_spawnuri_iso.dart"), [], null,
      // Setup handler as part of spawn.
      errorsAreFatal: false,
      onError: errorPort.sendPort);
}
