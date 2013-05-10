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

bar(x) {
  print(x);
}

main() {
  if (RunScript(testScript)) return;
  print("Hello from debuggee");
  var f = bar;
  f("closure call");
  bar(12);
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(22),      // Set breakpoint a line 22, at the closure call.
  Resume(),
  MatchFrame(0, "main"),  // Should be at closure call.
  StepInto(),
  MatchFrames(["bar", "main"]),  // Should be in closure function now.
  StepOut(),
  MatchFrame(0, "main"),  // Back in main, before static call to bar().
  SetBreakpoint(15),      // Breakpoint in bar();
  Resume(),
  MatchFrames(["bar", "main"]),
  Resume(),
];