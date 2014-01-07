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

// Check that if a breakpoint is requested on the line containing the
// one-liner with a local function below, the breakpoint gets set in
// the outer function.
foo(x) => (n) => x * n;  // Breakpoint 1 on this line.

// Check that if a breakpoint is requested on the line "return n*x"
// below, the breakpoint is set in the local function (closure).
bar(x) {
  return (n) {
    return n * x;  // Breakpoint 2 on this line.
  };
}

// Check that setting a breakpoint works in the case where the
// class has not been parsed yet.
// No reference to class C must appear in main(), so that the class is not
// yet parsed when the breakpoint in the closure nested in the constructor
// is set.
class C {
  var closure;
  C() {
    closure = () {
      var z = 10;  // Breakpoint 3 on this line.
      z = z * 2;
      return z;
    };
  }
}

checkBpInLazilyParsedClass() {
  var c = new C();
  c.closure(); // Expected to hit breakpoint.
}


main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  print("Hello from debuggee");
  var f = foo(10);  // Hits breakpoint.
  print(f(5));
  var b = bar(10);
  print(b(10)); // Hits breakpoint.
  checkBpInLazilyParsedClass();
}

// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(17),      // Breakpoint 1 in function foo.
  SetBreakpoint(23),      // Breakpoint 2 in local function inside bar.
  SetBreakpoint(36),      // Breakpoint 3 in local function inside constructor C.
  Resume(),
  MatchFrames(["foo", "main"]),
  Resume(),
  MatchFrames(["<anonymous closure>", "main"]),
  Resume(),
  MatchFrames(["C.<anonymous closure>", "checkBpInLazilyParsedClass"]),
  Resume(),
];
