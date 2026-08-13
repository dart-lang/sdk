// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check spawnUri accepts any program format that `dart` accepts. Currently this
// is source, kernel, AppJIT (blob container) and AppAOT (ELF).

import "dart:isolate";
import "dart:io";

import "package:expect/expect.dart";

int fib(int n) {
  if (n <= 1) return 1;
  return fib(n - 1) + fib(n - 2);
}

main(List<String> args, [dynamic sendPort]) {
  if (sendPort == null) {
    print("Parent start");
    var port = new RawReceivePort();
    port.handler = (result) {
      Expect.equals(14930352, result);
      port.close();
      print("Parent end");
    };
    print("Spawn ${Platform.script}");
    Isolate.spawnUri(Platform.script, <String>[], port.sendPort);
  } else {
    print("Child start");
    sendPort.send(fib(35));
    print("Child end");
  }
}
