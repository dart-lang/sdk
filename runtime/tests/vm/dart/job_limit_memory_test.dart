// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--verbose-gc

import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

import "job_helpers.dart";

doLeak() {
  dynamic leak = [];
  try {
    for (var i = 0; i < 100000; i++) {
      var bytes = new Uint8List(10 * 1024 * 1024);
      for (var j = 0; j < bytes.length; j++) {
        bytes[j] = j; // Ensure dirty page.
      }
      leak.add(bytes);
    }
  } catch (e) {
    leak = null;
    print("Caught OOM");
  }
  return leak;
}

main(List<String> args) async {
  if (args.contains("--child")) {
    print(doLeak()); // Block optimizing out.
    return;
  }

  if (Platform.isLinux) {
    var p = await runDocker([
      "--memory=400M",
      "--memory-swap=400M", // This includes regular memory.
    ]);
    Expect.equals(0, p.exitCode);
    Expect.contains("Caught OOM", p.stdout);

    p = await runSystemdRun([
      "--property=MemoryMax=400M",
      "--property=MemorySwapMax=0",
    ]);
    Expect.equals(0, p.exitCode);
    Expect.contains("Caught OOM", p.stdout);
  }

  if (Platform.isWindows) {
    var p = await runJobRun(["--memory", "${400 * 1024 * 1024}"]);
    Expect.equals(0, p.exitCode);
    Expect.contains("Caught OOM", p.stdout);
  }
}
