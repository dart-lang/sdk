// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

main() {
  try {
    RegExp ex = const RegExp(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } catch (Exception ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(@"^\w+$").hasMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } catch (Exception ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(@"^\w+$").firstMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } catch (Exception ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(@"^\w+$").allMatches(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } catch (Exception ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
  try {
    const RegExp(@"^\w+$").stringMatch(null);
    Expect.fail("Expected: NullPointerException got: no exception");
  } catch (Exception ex) {
    if (!(ex is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${ex}");
    }
  }
}
