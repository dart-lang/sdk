// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:io";
import "dart:ffi";

typedef CSleep = Void Function(Int32);
typedef DartSleep = void Function(int);

child(replyPort) {
  replyPort.send(null);

  var sleep = DynamicLibrary.process().lookupFunction<CSleep, DartSleep>(
    "sleep",
  );
  sleep(60 * 60);
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
