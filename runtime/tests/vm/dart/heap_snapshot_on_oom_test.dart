// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:expect/expect.dart";
import "use_flag_test_helper.dart";

main(List<String> arguments) async {
  if (arguments.contains("--testee")) {
    var x = [];
    while (true) {
      x = [x];
    }
    return;
  }

  // Snapshot write omitted from product mode.
  if (const bool.fromEnvironment("dart.vm.product")) return;

  await withTempDir("heap_snapshot_on_oom_test", (String dir) async {
    var exec = Platform.executable;
    var args = [
      ...Platform.executableArguments,
      "--heap_snapshot_on_oom=$dir/oom.heapsnapshot",
      "--old_gen_heap_size=50", // MB
      Platform.script.toFilePath(),
      "--testee",
    ];
    print("+ $exec ${args.join(' ')}");

    var result = Process.runSync(exec, args);
    print("Command stdout:");
    print(result.stdout);
    print("Command stderr:");
    print(result.stderr);

    Expect.equals(255, result.exitCode);
    Expect.contains("Out of Memory", result.stderr);

    Expect.isTrue(await File("$dir/oom.heapsnapshot").exists());
    Expect.isTrue(await File("$dir/oom.heapsnapshot").length() > 0);
  });
}
