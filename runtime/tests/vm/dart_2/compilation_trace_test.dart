// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:path/path.dart" as p;

import "snapshot_test_helper.dart";

int fib(int n) {
  if (n <= 1) return 1;
  return fib(n - 1) + fib(n - 2);
}

Future<void> main(List<String> args) async {
  if (args.contains("--child")) {
    print(fib(35));
    return;
  }

  if (!Platform.script.toString().endsWith(".dart")) {
    print("This test must run from source");
    return;
  }

  await withTempDir((String tmp) async {
    final String tracePath = p.join(tmp, "compilation_trace.txt");

    final result1 = await runDart("generate compilation trace", [
      "--save_compilation_trace=$tracePath",
      Platform.script.toFilePath(),
      "--child",
    ]);
    expectOutput("14930352", result1);

    final result2 = await runDart("use compilation trace", [
      "--load_compilation_trace=$tracePath",
      Platform.script.toFilePath(),
      "--child",
    ]);
    expectOutput("14930352", result2);
  });
}
