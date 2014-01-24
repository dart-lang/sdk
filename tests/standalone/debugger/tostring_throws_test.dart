// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "debug_lib.dart";

main(List<String> arguments) {
  if (RunScript(testScript, arguments)) return;

  Foo foo = new Foo();

  print("Hello from debuggee");
}

class Foo {
  String toString() {
    throw 'I always throw';
  }
}

// Make sure Foo.toString() does not get called.
var testScript = [
  MatchFrame(0, "main"),
  SetBreakpoint(12),
  Resume(),
  MatchFrame(0, "main"),
  MatchLocals({"foo": "object of type Foo"}),
  Resume(),
];
