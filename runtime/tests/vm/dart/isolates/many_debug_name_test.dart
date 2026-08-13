// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

child(replyPort) {
  for (var i = 0; i < 10; i++) {
    replyPort.send(Isolate.current.debugName);
  }
}

main() async {
  var pending = 0;
  var port = new RawReceivePort();
  port.handler = (_) {
    pending--;
    if (pending == 0) port.close();
  };
  for (var i = 0; i < 20; i++) {
    pending += 10;
    Isolate.spawn(child, port.sendPort);
  }
}
