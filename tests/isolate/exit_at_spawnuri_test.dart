// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherScripts=exit_at_spawnuri_iso.dart

library exit_at_spawn;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();

  RawReceivePort exitPort = new RawReceivePort();
  exitPort.handler = (message) {
    Expect.equals(null, message);
    exitPort.close();
    asyncEnd();
  };

  Isolate.spawnUri(Uri.parse("exit_at_spawnuri_iso.dart"), [], null,
      // Setup handler as part of spawn.
      errorsAreFatal: false,
      onExit: exitPort.sendPort);
}
