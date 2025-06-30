// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

child(replyPort) async {
  var ops = <Future>[];
  for (var i = 0; i < 32; i++) {
    ops.add(File(Platform.executable).stat()); // Uses the IO Service.
  }
  await Future.wait(ops);
  replyPort.send(null);
}

main() {
  var pending = 1000;
  var port = new RawReceivePort();
  port.handler = (_) {
    pending--;
    if (pending == 0) port.close();
  };
  for (var i = 0; i < pending; i++) {
    Isolate.spawn(child, port.sendPort);
  }
}
