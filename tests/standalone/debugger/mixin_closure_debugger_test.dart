// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs this dart script as
// a debug target.
// Run this test with option --wire to see the json messages sent
// between the processes.
// Run this test with option --verbose to see the stdout and stderr output
// of the debug target process.

// This test checks that a breakpoint can be set and is hit in a closure
// inside a mixin function. Regression test for issue 15325.

import "debug_lib.dart";

class S { }

class M {
  m()  {
    var sum = 0;
    [1,2,3].forEach((e) {
      sum += e;  // Breakpoint here.
    });
    return sum;
  }
}

class A = S with M;

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  var a = new A();
  print(a.m());
}

// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(23),      // Set breakpoint inside the forEach closure.
  Resume(),
  MatchFrames(["S&M.<anonymous closure>", "forEach", "S&M.m"],
              exactMatch: false),  // First iteration.
  MatchLocals({"e": "1"}),
  Resume(),
  MatchFrames(["S&M.<anonymous closure>", "forEach", "S&M.m"],
              exactMatch: false),  // Second iteration.
  MatchLocals({"e": "2"}),
  Resume(),
  MatchFrames(["S&M.<anonymous closure>", "forEach", "S&M.m"],
              exactMatch: false),  // Third iteration.
  MatchLocals({"e": "3"}),
  Resume(),
];
