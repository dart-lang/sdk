// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `await` can handle a future with a non-native stack trace.

import "dart:async";
import "package:expect/expect.dart";

class Blah implements StackTrace {
  Blah(this._trace);

  toString() {
    return "Blah " + _trace.toString();
  }

  var _trace;
}

foo() {
  var x = "\nBloop\nBleep\n";
  return Future.error(42, Blah(x));
}

main() async {
  try {
    await foo();
    Expect.fail("Should not reach here.");
  } on int catch (e, s) {
    Expect.equals(42, e);
    Expect.equals("Blah \nBloop\nBleep\n", s.toString());
    return;
  }
  Expect.fail("Unreachable.");
}
