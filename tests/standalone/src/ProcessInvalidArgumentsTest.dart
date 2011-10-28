// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that invalid arguments throw exceptions.

void testNonStringPath() {
  try {
    Process p = new Process(["true"], []);
    Expect.fail("Did not throw exception");
  } catch(var e) {
    Expect.isTrue(e is ProcessException, "Wrong exception type: $e");
  }
}

void testNonListArguments() {
  try {
    Process p = new Process("true", "asdf");
    Expect.fail("Did not throw exception");
  } catch(var e) {
    Expect.isTrue(e is ProcessException, "Wrong exception type: $e");
  }
}

void testNonStringArgument() {
  try {
    Process p = new Process("true", ["asdf", 1]);
    Expect.fail("Did not throw exception");
  } catch(var e) {
    Expect.isTrue(e is ProcessException, "Wrong exception type: $e");
  }
}

void main() {
  testNonStringPath();
  testNonListArguments();
  testNonStringArgument();
}
