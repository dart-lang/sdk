// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs this dart script as
// a debug target.
// Run this test with option --wire to see the json messages sent
// between the processes.
// Run this test with option --verbose to see the stdout and stderr output
// of the debug target process.

import "debug_lib.dart";

foo() {
  var y;  // Breakpoint
  return 123;
}

test() {
  if (true) {
    var temp = 777;
  }
  if (true) {
    var a = foo();  // Breakpoint
    if (true) {
      var s = 456;
      print(s);
    }
  }
}

test_no_init() {
  if (true) {
    var temp = 777;
  }
  if (true) {
    var a;  // Breakpoint
    if (true) {
      var s = 456;
      print(s);
    }
  }
}


main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  print("Hello from debuggee");
  test();
  test_no_init();
  print("Hello again");
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  Step(),
  MatchFrame(0, "main"),  // Should still be in "main".
  SetBreakpoint(15),  // Set breakpoint in function foo.
  SetBreakpoint(24),  // Set breakpoint in function test.
  SetBreakpoint(37),  // Set breakpoint in function test_no_init.
  Resume(),
  MatchFrames(["test", "main"]),
  AssertLocalsNotVisible(["a"]),  // Here, a is not in scope yet.
  Resume(),
  MatchFrames(["foo", "test", "main"]),
  AssertLocalsNotVisible(["a"], 1),  // In the caller, a is not in scope.
  Step(),
  MatchLocals({"y": "null"}),  // Expect y initialized to null.
  Resume(),
  MatchFrames(["test_no_init", "main"]),
  AssertLocalsNotVisible(["a"]),  // a is not in scope.
  Step(),
  MatchLocals({"a": "null"}),
  Resume()
];
