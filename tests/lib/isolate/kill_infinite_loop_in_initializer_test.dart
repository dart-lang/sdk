// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test against out-of-band messages being blocked during lazy
// static field initialization.

import "dart:isolate";
import "package:async_helper/async_helper.dart";

dynamic staticFieldWithBadInitializer = badInitializer();

badInitializer() {
  print("badInitializer");
  for (;;) {}
  return 42; // Unreachable.
}

child(message) {
  print("child");
  RawReceivePort port = new RawReceivePort();
  print(staticFieldWithBadInitializer);
  port.close(); // Unreachable.
}

void main() {
  asyncStart();
  Isolate.spawn(child, null).then((Isolate isolate) {
    print("spawned");
    late RawReceivePort exitSignal;
    exitSignal = new RawReceivePort((_) {
      print("onExit");
      exitSignal.close();
      asyncEnd();
    });
    isolate.addOnExitListener(exitSignal.sendPort);
    isolate.kill(priority: Isolate.immediate);
  });
}
