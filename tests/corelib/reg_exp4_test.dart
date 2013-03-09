// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

main() {
  try {
    RegExp ex = new RegExp(null);
    Expect.fail("Expected: ArgumentError got: no exception");
  } catch (ex) {
    if (!(ex is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${ex}");
    }
  }
  try {
    new RegExp(r"^\w+$").hasMatch(null);
    Expect.fail("Expected: ArgumentError got: no exception");
  } catch (ex) {
    if (!(ex is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${ex}");
    }
  }
  try {
    new RegExp(r"^\w+$").firstMatch(null);
    Expect.fail("Expected: ArgumentError got: no exception");
  } catch (ex) {
    if (!(ex is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${ex}");
    }
  }
  try {
    new RegExp(r"^\w+$").allMatches(null);
    Expect.fail("Expected: ArgumentError got: no exception");
  } catch (ex) {
    if (!(ex is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${ex}");
    }
  }
  try {
    new RegExp(r"^\w+$").stringMatch(null);
    Expect.fail("Expected: ArgumentError got: no exception");
  } catch (ex) {
    if (!(ex is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${ex}");
    }
  }
}
