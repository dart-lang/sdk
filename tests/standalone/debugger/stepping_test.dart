// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "debug_lib.dart";

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;

  bar();
}

void bar() {
  print('foo1');
  print('foo2');
  print('foo3');
}

/**
 * Set a breakpoint, resume to that breakpoint, step once, and verify that the
 * step worked.
 */
var testScript = [
  MatchFrames(["main"]),
  SetBreakpoint(15),
  Resume(),
  MatchFrames(["bar"]),
  Step(),
  MatchFrames(["bar"]),
  Resume(),
];
