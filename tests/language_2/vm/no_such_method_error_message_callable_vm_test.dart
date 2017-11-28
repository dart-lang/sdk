// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test error message with noSuchMethodError: non-existent names
// should result in a message that reports the missing method.

class Callable {
  call() {}
}

call_bar(x) => x.bar();
call_with_bar(x) => x("bar");

testMessageProp() {
  try {
    call_bar(new Callable());
  } catch (e) {
    Expect.isTrue(e.toString().contains("has no instance method 'bar'"));
  }
}

testMessageCall() {
  try {
    call_with_bar(new Callable());
  } catch (e) {
    final noMatchingArgs =
        "has no instance method 'call' with matching arguments";
    Expect.isTrue(e.toString().contains(noMatchingArgs));
  }
}

main() {
  for (var i = 0; i < 20; i++) testMessageProp();
  for (var i = 0; i < 20; i++) testMessageCall();
}
