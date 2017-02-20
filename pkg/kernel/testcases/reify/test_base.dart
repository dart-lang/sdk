// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_base;

expectIs(expected, actual, [String note]) {
  if (expected != actual) {
    if (note != null) {
      throw "Expected: '$expected': $note, actual: '$actual'";
    }
    throw "Expected: '$expected', actual: '$actual'";
  }
}

expectTrue(actual) => expectIs(true, actual);

expectFalse(actual) => expectIs(false, actual);

expectThrows(f(), test(e)) {
  var exception = false;
  String note = null;
  try {
    f();
  } catch (e) {
    exception = test(e);
    if (!exception) {
      note = "$e [${e.runtimeType}]";
    }
  }
  expectIs(true, exception, note);
}

expectOutput(String expected) => expectIs(expected, output);

String output;

write(o) {
  output = output == null ? "$o" : "$output\n$o";
}
