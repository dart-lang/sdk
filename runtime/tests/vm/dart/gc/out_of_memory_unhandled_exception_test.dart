// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

main(args) async {
  if (args.contains("--child")) {
    var leak = [];
    while (true) {
      leak = [leak];
    }
  } else {
    var exec = Platform.resolvedExecutable;
    var args = <String>[];
    args.addAll(Platform.executableArguments);
    args.add("--old_gen_heap_size=20");
    args.add(Platform.script.toFilePath());
    args.add("--child");

    // Should report an unhandled out of memory exception without crashing.
    print("+ $exec " + args.join(" "));
    var result = await Process.run(exec, args);

    print("exit: ${result.exitCode}");
    print("stdout:");
    print(result.stdout);
    print("stderr:");
    print(result.stderr);

    Expect.equals(255, result.exitCode, "Unhandled exception, not crash");
    Expect.isTrue(result.stderr.contains("Out of Memory"));
  }
}
