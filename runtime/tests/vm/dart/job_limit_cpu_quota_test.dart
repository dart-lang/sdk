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
      var p = await runDocker(["--cpus=$input"]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testDocker("0.5", "1");
    await testDocker("1", "1");
    await testDocker("1.5", "2");
    await testDocker("2", "2");

    // Docker won't let us overshoot.

    testSystemdRun(input, output) async {
      var p = await runSystemdRun(["--property=CPUQuota=$input"]);
      Expect.equals(0, p.exitCode);
      Expect.containsAny([
        "Platform.numberOfProcessors: $output\n",
        // On Ubuntu Jammy, the limit doesn't take effect.
        "Platform.numberOfProcessors: ${Platform.numberOfProcessors}",
      ], p.stdout);
    }

    await testSystemdRun("50%", "1");
    await testSystemdRun("100%", "1");
    await testSystemdRun("150%", "2");
    await testSystemdRun("200%", "2");

    // The underlying cgroup limits are allowed to exceed the number of cpus.
    // We should answer the minimum of the two.
    await testSystemdRun("1000000%", "${Platform.numberOfProcessors}");
  }

  if (Platform.isWindows) {
    testJobRun(input, output) async {
      var p = await runJobRun(["--cpu-percent", input]);
      Expect.equals(0, p.exitCode);
      Expect.contains("Platform.numberOfProcessors: $output", p.stdout);
    }

    await testJobRun("50", "1");
    await testJobRun("100", "1");
    await testJobRun("150", "2");
    await testJobRun("200", "2");

    // Windows jobs won't let us overshoot.
  }
}
