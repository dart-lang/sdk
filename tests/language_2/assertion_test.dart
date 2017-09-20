// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts

// Dart test program testing assert statements.

import "package:expect/expect.dart";

testTrue() {
  int i = 0;
  try {
    assert(true);
  } on AssertionError {
    i = 1;
  }
  return i;
}

testFalse() {
  int i = 0;
  try {
    assert(false);
  } on AssertionError {
    i = 1;
  }
  return i;
}

unknown(dynamic a) {
  return a ? true : false;
}

testClosure(bool f()) {
  int i = 0;
  try {
    assert(f);
  } on AssertionError {
    i = 1;
  }
  return i;
}

testBoolean(bool value) {
  int i = 0;
  try {
    assert(value);
  } on AssertionError {
    i = 1;
  }
  return i;
}

testDynamic(dynamic value) {
  int i = 0;
  try {
    assert(value);
  } on AssertionError {
    i = 1;
  }
  return i;
}

testMessage(value, message) {
  try {
    assert(value, message);
    return null;
  } catch (error) {
    // Catch any type to allow the Boolean conversion to throw either
    // AssertionError or TypeError.
    return error;
  }
}

main() {
  Expect.equals(0, testTrue());
  Expect.equals(0, testBoolean(true));
  Expect.equals(0, testDynamic(unknown(true)));

  Expect.equals(1, testFalse());
  Expect.equals(1, testBoolean(false));
  Expect.equals(1, testDynamic(unknown(false)));

  Expect.equals(1, testBoolean(null));
  Expect.equals(1, testDynamic(null));
  Expect.equals(1, testDynamic(42));
  Expect.equals(1, testClosure(() => true));
  Expect.equals(1, testDynamic(() => true));
  Expect.equals(1, testClosure(() => false));
  Expect.equals(1, testDynamic(() => false));
  Expect.equals(1, testDynamic(() => 42));
  Expect.equals(1, testDynamic(() => null));
  Expect.equals(1, testClosure(() => null));

  Expect.equals(1234, testMessage(false, 1234).message);
  Expect.equals('hi', testMessage(false, 'hi').message);

  // These errors do not have the message because boolean conversion failed.
  Expect.notEquals(1234, testMessage(null, 1234).message);
  Expect.notEquals('hi', testMessage(null, 'hi').message);
  Expect.notEquals('hi', testMessage(() => null, 'hi').message);
  Expect.notEquals('hi', testMessage(() => false, 'hi').message);
  Expect.notEquals('hi', testMessage(() => true, 'hi').message);
}
