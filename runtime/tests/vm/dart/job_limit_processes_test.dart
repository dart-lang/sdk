// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// On Linux, threads and processes consume the same resource. Avoid VM threads
// starting in the middle of the test.
// VMOptions=--no-background-compilation --no-concurrent-mark --no-concurrent-sweep --scavenger-tasks=1 --marker-tasks=1

import "dart:io";

import "package:expect/expect.dart";

import "job_helpers.dart";

main(List<String> args) async {
  if (args.contains("--child")) {
    sleep(Duration(seconds: 5)); // ~Wait for service isolate to settle.

    var exits = <Future>[];
    for (var i = 0; i < 100; i++) {
      if (Platform.isWindows) {
        var p = await Process.start("cmd.exe", ["/c", "timeout", "/t", "1000"]);
        exits.add(p.exitCode);
      } else {
        var p = await Process.start("sleep", ["1000"]);
        exits.add(p.exitCode);
      }
    }
    print(await Future.wait(exits));
    print("done");
    return;
  }

  if (Platform.isLinux) {
    var p = await runDocker(["--pids-limit=10"]);
    Expect.notEquals(0, p.exitCode);
    Expect.contains(
      "ProcessException: Resource temporarily unavailable",
      p.stderr,
    );

    p = await runSystemdRun(["--property=TasksMax=10"]);
    Expect.notEquals(0, p.exitCode);
    Expect.contains(
      "ProcessException: Resource temporarily unavailable",
      p.stderr,
    );
  }

  if (Platform.isWindows) {
    var p = await runJobRun(["--processes", "10"]);
    Expect.notEquals(0, p.exitCode);
    Expect.contains(
      "ProcessException: Not enough quota is available to process this command",
      p.stderr,
    );
  }
}
