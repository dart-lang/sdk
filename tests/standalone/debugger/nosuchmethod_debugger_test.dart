// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs this dart script as
// a debug target.
// Run this test with option --wire to see the json messages sent
// between the processes.
// Run this test with option --verbose to see the stdout and stderr output
// of the debug target process.

import "debug_lib.dart";

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  print("Hello from debuggee");
  var a = new A();
  for (var i = 0; i < 2; ++i) {
    a.foo(i);
  }
}

class A {
  noSuchMethod(m) {
    print(m.positionalArguments[0]);
  }
}

// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(19),      // Set breakpoint at a.foo(i).
  Resume(),
  MatchFrame(0, "main"),  // Should be at closure call.
  MatchLocals({"i": "0"}),
  StepInto(),
  StepInto(),
  MatchFrames(["A.noSuchMethod", "main"]),
  StepOut(),
  MatchFrame(0, "main"),  // Back in main.
  Resume(),
  MatchFrame(0, "main"),  // Still in main back at a.foo(i).
  MatchLocals({"i": "1"}),
  StepInto(),
  StepInto(),
  MatchFrames(["A.noSuchMethod", "main"]),  // Second invocation.
  Resume()
];
