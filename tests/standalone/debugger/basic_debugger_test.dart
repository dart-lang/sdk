// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

foo(i) {
  bar("baz");
  print(i);
}

main() {
  if (RunScript(testScript)) return;
  print("Hello from debuggee");
  foo(42);
  print("Hello again");
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  Step(),
  MatchFrame(0, "main"),  // Should still be in "main".
  SetBreakpoint(15),  // Set breakpoint a line 15, in function bar.
  Resume(),
  MatchFrames(["bar", "foo", "main"]),
  MatchFrame(1, "foo"),
  Resume(),
];