// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts
// dart2jsOptions=--enable-asserts

// Dart test program testing assert statements.

import "package:expect/expect.dart";

int testTrue() {
  int i = 0;
  try {
    assert(true);
  } on AssertionError {
    i = 1;
  }
  return i;
}

int testFalse() {
  int i = 0;
  try {
    assert(false);
  } on AssertionError {
    i = 1;
  }
  return i;
}

dynamic unknown(dynamic a) {
  return a ? true : false;
}

int testBoolean(bool value) {
  int i = 0;
  try {
    assert(value);
  } on AssertionError {
    i = 1;
  }
  return i;
}

int testDynamic(dynamic value) {
  int i = 0;
  try {
    assert(value);
  } on AssertionError {
    i = 1;
  }
  return i;
}

AssertionError testMessage(value, message) {
  try {
    assert(value, message);
  } on AssertionError catch (error) {
    return error;
  }
  return null;
}

main() {
  Expect.equals(0, testTrue());
  Expect.equals(0, testBoolean(true));
  Expect.equals(0, testDynamic(unknown(true)));

  Expect.equals(1, testFalse());
  Expect.equals(1, testBoolean(false));
  Expect.equals(1, testDynamic(unknown(false)));

  Expect.throwsTypeError(() => testBoolean(null));
  Expect.throwsTypeError(() => testDynamic(null));
  Expect.throwsTypeError(() => testDynamic(42));
  Expect.throwsTypeError(() => testDynamic(() => true));
  Expect.throwsTypeError(() => testDynamic(() => false));
  Expect.throwsTypeError(() => testDynamic(() => 42));
  Expect.throwsTypeError(() => testDynamic(() => null));

  Expect.equals(1234, testMessage(false, 1234).message);
  Expect.equals('hi', testMessage(false, 'hi').message);
}
