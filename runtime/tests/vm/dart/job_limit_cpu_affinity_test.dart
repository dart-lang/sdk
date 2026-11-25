// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

import "job_helpers.dart";

main(List<String> args) async {
  if (args.contains("--child")) {
    print("Platform.numberOfProcessors: ${Platform.numberOfProcessors}");
    return;
  }

  if (Platform.isLinux) {
    testDocker(input, output) async {
      var p = await runDocker(["--cpuset-cpus=$input"]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testDocker("0", "1");
    await testDocker("0-1", "2");

    // systemd-run --user --scope cannot use CPUAffinity.

    testTaskset(input, output) async {
      var p = await runTaskset(["-c", input]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testTaskset("0", "1");
    await testTaskset("0-1", "2");
  }

  if (Platform.isWindows) {
    testJobRun(input, output) async {
      var p = await runJobRun(["--cpu-mask", input]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testJobRun("1", "1");
    await testJobRun("3", "2");

    testStart(input, output) async {
      var p = await runStart(["/affinity", input]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testStart("0x1", "1");
    await testStart("0x3", "2");
  }
}
