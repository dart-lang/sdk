// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "debug_lib.dart";

class MyClass {
  operator ==(other) {
    print(other);
    return true;  // Breakpoint #3.
  }
}

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;
  var a = new MyClass();
  var b = null;
  a == b;  // Breakpoint #1.
  print("after 1");
  b = 123;
  a == b;  // Breakpoint #2.
  print("after 2");
  a == null;  // Breakpoint #4.
  print("after 4");
  if (null == a) {
    throw "unreachable";
  }
  print("ok");
}

// Checks that debugger can stop at calls to == even if one
// of the operands is null.

var testScript = [
  MatchFrames(["main"]),
  MatchLine(15),
  SetBreakpoint(18),
  SetBreakpoint(21),
  SetBreakpoint(10),
  SetBreakpoint(23),
  Resume(),
  MatchFrames(["main"]),
  MatchLine(18),  // At breakpoint #1.
  Resume(),
  MatchLine(21),  // At breakpoint #2; didn't hit breakpoint in MyClass.==.
  Resume(),
  MatchFrames(["MyClass.==", "main"]),
  MatchLine(10),  // At breakpoint #3 in MyClass.==.
  Resume(),
  MatchLine(23),  // At breakpoint #4.
  Resume()
];
