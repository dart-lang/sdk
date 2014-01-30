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

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  print("Hello from debuggee");
  [1,2].forEach(bar);  // Causes implicit closure of bar to be compiled.
  print("stop here");  // Stop here and set breakpoint in bar.
  [3,4].forEach(bar);  // Call bar closure and observe breakpoints being hit.
  print("done");
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(22),      // Set breakpoint a line 22, after bar closure is compiled.
  Resume(),
  MatchFrame(0, "main"),  // Should be at line 22 in main.
  MatchLine(22),
  SetBreakpoint(15),      // Set breakpoint in function bar. Bar has not been called
                          // through a regular function call at this point, only
                          // through a closure from forEach().
  Resume(),
  MatchFrames(["bar", "forEach", "main"]),  // Should be in closure function now.
  MatchLine(15),
  MatchLocals({"x": "3"}),
  Resume(),
  MatchFrames(["bar", "forEach", "main"]),  // Should be in closure function now.
  MatchLine(15),
  MatchLocals({"x": "4"}),
  Resume(),
];
