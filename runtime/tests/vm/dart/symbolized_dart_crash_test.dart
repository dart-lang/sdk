// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:ffi";

import "package:expect/expect.dart";

@pragma("vm:never-inline")
@pragma("vm:entry-point") /* block mangling */
dartFunctionName() {
  Pointer<Uint8>.fromAddress(0).value = 0;
}

@pragma("vm:never-inline")
@pragma("vm:entry-point") /* block mangling */
main(List<String> arguments) {
  if (arguments.contains("--testee")) {
    dartFunctionName();
    return;
  }

  var result = Process.runSync(Platform.resolvedExecutable, [
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--testee",
  ]);
  print(result.exitCode);
  print(result.stdout);
  print(result.stderr);

  Expect.contains("===== CRASH =====", result.stderr);
  Expect.contains("dartFunctionName", result.stderr);
  Expect.contains("main", result.stderr);
}
