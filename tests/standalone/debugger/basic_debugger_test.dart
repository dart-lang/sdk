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
  var localStr = "foo";
  int localInt = 1;
  double localDouble = 1.1;
  
  print(x);
}

bam(a) => bar(a);

foo(i) {
  bar("baz");
  print(i);
}

main() {
  if (RunScript(testScript)) return;
  print("Hello from debuggee");
  foo(42);
  bam("bam");
  print("Hello again");
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  Step(),
  MatchFrame(0, "main"),  // Should still be in "main".
  SetBreakpoint(19),  // Set breakpoint a line 19, in function bar.
  Resume(),
  MatchFrames(["bar", "foo", "main"]),
  MatchFrame(1, "foo"),
  MatchLocals({"localStr": '"foo"', "localInt": "1", "localDouble": "1.1", 
      "x": '"baz"'}),
  SetBreakpoint(22),  // Set breakpoint a line 22, in function bam.
  Resume(),
  MatchFrames(["bam", "main"]),
  Resume(),
  MatchFrames(["bar", "bam", "main"]),
  Resume(),
];