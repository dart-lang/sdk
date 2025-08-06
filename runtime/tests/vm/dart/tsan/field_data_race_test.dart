// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--experimental-shared-data

import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

class Box {
  int foo = 0;
}

@pragma("vm:shared")
Box box = Box();

@pragma("vm:never-inline")
noopt() {}

@pragma("vm:never-inline")
dataRaceFromMain() {
  final localBox = box;
  for (var i = 0; i < 1000000; i++) {
    localBox.foo += 1;
    noopt();
  }
}

@pragma("vm:never-inline")
dataRaceFromChild() {
  final localBox = box;
  for (var i = 0; i < 1000000; i++) {
    localBox.foo += 1;
    noopt();
  }
}

child(_) {
  dataRaceFromChild();
}

main(List<String> arguments) {
  if (arguments.contains("--testee")) {
    print(box); // side effect initialization
    Isolate.spawn(child, null);
    dataRaceFromMain();
    return;
  }

  var exec = Platform.executable;
  var args = [
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--testee",
  ];
  print("+ $exec ${args.join(' ')}");

  var result = Process.runSync(exec, args);
  print("Command stdout:");
  print(result.stdout);
  print("Command stderr:");
  print(result.stderr);

  Expect.notEquals(0, result.exitCode);
  Expect.contains("ThreadSanitizer: data race", result.stderr);
  Expect.contains("of size 8", result.stderr);
  Expect.contains("dataRaceFromMain", result.stderr);
  Expect.contains("dataRaceFromChild", result.stderr);
}
