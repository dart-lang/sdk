// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "debug_lib.dart";

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;

  bar();

  print("Hello from debuggee");
}

bar() {

  print("bar");
}

var testScript = [
  MatchFrame(0, "main"),
  SetBreakpoint(10),
  SetBreakpoint(12),
  SetBreakpoint(16),
  Resume(),
  MatchFrame(0, "main"),
  Resume(),
  MatchFrame(0, "bar"),
  Resume(),
  MatchFrame(0, "main"),
  ExpectEvent("breakpointResolved", {"breakpointId": 1}),
  ExpectEvent("breakpointResolved", {"breakpointId": 2}),
  ExpectEvent("breakpointResolved", {"breakpointId": 3}),
  Resume(),
];
