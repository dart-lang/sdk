// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_exit_at_spawnuri_iso;

import "dart:isolate";

main(args, replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    switch (v) {
      case 0:
        replyPort.send(42);
        break;
      case 1:
        throw new ArgumentError("whoops");
      case 2:
        throw new RangeError.value(37);
      case 3:
        port.close();
    }
  };
  replyPort.send(port.sendPort);
}
