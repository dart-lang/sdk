// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to verify that a breakpoint can be set in code that is not yet
// loaded, i.e. in a deferred library.
//
// This test forks a second vm process that runs this dart script as
// a debug target.
// Run this test with option --wire to see the json messages sent
// between the processes.
// Run this test with option --verbose to see the stdout and stderr output
// of the debug target process.

import "debug_lib.dart";
import "deferred_code_lib.dart" deferred as D;


main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  var loaded = false;
  print("Hello from debuggee");
  D.loadLibrary().then((_) {
    loaded = true;
    print("Done loading deferred library");
    D.stopTheBuck();
  });
  print("main terminates");
}


// Expected debugger events and commands.
var testScript = [
  MatchFrame(0, "main"),  // Top frame in trace is function "main".
  SetBreakpoint(22),  // Breakpoint just before call to loadLibrary().
  Resume(),
  // Set BP in deferred library code before the loadLibrary() call is executed.
  MatchFrame(0, "main"),
  MatchLine(22),
  MatchLocals({"loaded": "false"}),
  SetBreakpoint(10, url: "deferred_code_lib.dart"),
  // Regression test: we used to have a bug that hung the debugger when
  // processing latent brakepoints for urls that have no match.
  // The BP below will not match any loaded file.
  SetBreakpoint(10, url: "non_existing_file.dart"),
  Resume(),
  MatchFrame(0, "stopTheBuck"),  // Expect to be stopped in deferred library code.
  // MatchLine(10), // Line matching only works for the main script.
  Resume(),
];
