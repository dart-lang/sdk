// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

import "job_helpers.dart";

childIsolate(replyPort) {
  sleep(Duration(hours: 1)); // Consume thread.
  replyPort.send(null);
}

main(List<String> args) async {
  if (args.contains("--child")) {
    var pending = 0;
    var port = new RawReceivePort();
    port.handler = (_) {
      pending--;
      if (pending == 0) {
        port.close();
      }
    };
    for (var i = 0; i < 100; i++) {
      Isolate.spawn(childIsolate, port.sendPort);
      pending++;
    }
    return;
  }

  if (Platform.isLinux) {
    var p = await runDocker(["--pids-limit=10"]);
    Expect.notEquals(0, p.exitCode);
    Expect.contains("Could not start thread DartWorker", p.stderr);

    p = await runSystemdRun(["--property=TasksMax=10"]);
    Expect.notEquals(0, p.exitCode);
    Expect.contains("Could not start thread DartWorker", p.stderr);
  }

  if (Platform.isWindows) {
    // Jobs cannot limit the number of threads.
  }
}
