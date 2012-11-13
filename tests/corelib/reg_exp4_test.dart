// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

main() {
  try {
    RegExp ex = const RegExp(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } on Exception catch (ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(r"^\w+$").hasMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } on Exception catch (ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(r"^\w+$").firstMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } on Exception catch (ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(r"^\w+$").allMatches(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } on Exception catch (ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(r"^\w+$").stringMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } on Exception catch (ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
}
