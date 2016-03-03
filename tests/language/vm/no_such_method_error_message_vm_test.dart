// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test error message with noSuchMethodError: non-existent names
// should result in a "method not found" message.

call_bar(x) => x.bar();

testMessage() {
  try {
    call_bar(5);
  } catch (e) {
    Expect.isTrue(e.toString().indexOf("method not found") != -1);
  }
}


main() {
  for (var i = 0; i < 20; i++) testMessage();
}

