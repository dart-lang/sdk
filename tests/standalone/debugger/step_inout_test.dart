// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "debug_lib.dart";

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;

  foo('foo1');
  foo('foo2');
  foo('foo3');
}

void foo(String str) {
  print(str);
}

/**
 * Set a breakpoint, resume to that breakpoint, step into a method, step out,
 * step over the next line, and resume execution.
 */
var testScript = [
  MatchFrames(["main"]),
  SetBreakpoint(10),
  Resume(),
  MatchFrames(["main"]),
  StepInto(),
  MatchFrames(["foo", "main"]),
  StepOut(),
  MatchFrames(["main"]),
  Step(),
  MatchFrames(["main"]),
  Resume(),
];
