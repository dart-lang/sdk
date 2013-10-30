// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
  var x = a == b;  // Breakpoint #1.
  print(x);
  b = 123;
  a == b;  // Breakpoint #2.
  print("after 2");
  if (a == null) {  // Breakpoint #4.
    throw "unreachable";
  }
  print("after 4");
  if (null == a) {
    throw "unreachable";
  }
  print("ok");
}

var testScript = [
  MatchFrames(["main"]),
  SetBreakpoint(18),
  SetBreakpoint(21),
  SetBreakpoint(10),
  SetBreakpoint(23),
  Resume(),
  MatchFrames(["main"]),  // At breakpoint #1.
  StepInto(),
  MatchFrames(["main"]),  // Don't step into == method because of null.
  Resume(),
  MatchFrames(["main"]), // At breakpoint #2.
  StepInto(),
  StepInto(),
  MatchFrames(["MyClass.==", "main"]),  // At MyClass.== entry.
  Resume(),
  MatchFrames(["MyClass.==", "main"]),  // At breakpoint #3.
  Resume(),
  MatchFrames(["main"]), // At breakpoint #4.
  StepInto(),
  MatchFrames(["main"]), // After breakpoint #4.
  Step(),
  MatchFrames(["main"]), // At null == a.
  StepInto(),
  MatchFrames(["main"]), // After null == a.
  Resume()
];
