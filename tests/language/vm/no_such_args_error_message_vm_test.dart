// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation --no-lazy-dispatchers

import "package:expect/expect.dart";

// Test error message with misusing Functions and Closures: wrong args
// should result in a message that reports the missing method.

call_with_bar(x) => x("bar");

testClosureMessage() {
  try {
    call_with_bar(() {});
  } catch (e) {
    final expectedStrings = [
      'Tried calling: testClosureMessage.<anonymous closure>("bar")',
    ];
    Expect.stringContainsInOrder(e.toString(), expectedStrings);
  }
}

noargs() {}

testFunctionMessage() {
  try {
    call_with_bar(noargs);
  } catch (e) {
    final expectedStrings = [
      'Tried calling: noargs("bar")',
    ];
    Expect.stringContainsInOrder(e.toString(), expectedStrings);
  }
}

main() {
  for (var i = 0; i < 20; i++) testClosureMessage();
  for (var i = 0; i < 20; i++) testFunctionMessage();
}
