// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:io";

child(replyPort) {
  replyPort.send(null);
  Process.runSync("sleep", ["3600"]);
}

main() async {
  var pending = 0;
  var port;
  port = new RawReceivePort((msg) {
    pending--;
    if (pending == 0) exit(0);
  });

  for (var i = 0; i < 20; i++) {
    Isolate.spawn(child, port.sendPort);
    pending++;
  }
}
