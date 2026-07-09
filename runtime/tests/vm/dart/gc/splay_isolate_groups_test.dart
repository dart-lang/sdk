// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--pointer_cage=true
// VMOptions=--pointer_cage=false

import "dart:isolate";
import "dart:io";
import "splay_test.dart" as test;

void main(args, message) {
  if (args.contains("--child")) {
    test.main();
    (message as SendPort).send("Done");
    return;
  }

  for (var i = 0; i < 2; i++) {
    var port;
    port = new RawReceivePort((_) {
      port.close();
    });
    Isolate.spawnUri(Platform.script, ["--child"], port.sendPort);
  }
}
