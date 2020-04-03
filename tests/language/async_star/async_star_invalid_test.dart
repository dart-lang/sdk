// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that various invalid uses of `yield` are disallowed.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var yield = 42;

main() async {
  asyncStart();
  Stream<String> f() async* {
    // Invalid syntax.
    yield ("a", "b"); //# 01: syntax error
    yield yield "twice"; //# 02: syntax error

    // Valid but curious syntax.
    yield throw "throw"; //# 03: runtime error

    // Type error.
    yield* "one"; //# 04: compile-time error

    label: yield "ok";
  }
  var completer = Completer();
  f().listen(completer.complete, onError: completer.completeError,
      onDone: () {
        if (!completer.isCompleted) completer.completeError("not ok?");
      });
  Expect.equals("ok", await completer.future);
  asyncEnd();
}
