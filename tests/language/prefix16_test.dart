// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved imported symbols are treated as dynamic
// In this test, the function myFunc contains malformed types because
// lib12.Library13 is not resolved.

library Prefix16NegativeTest.dart;

import "package:expect/expect.dart";
import "library12.dart" as lib12;

typedef lib12.Library13 myFunc(lib12.Library13 param);
typedef lib12.Library13 myFunc2(lib12.Library13 param, int i);

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

main() {
  {
    bool got_type_error = false;
    try {
      // Malformed myFunc treated as (dynamic) => dynamic.
      myFunc i = 0;
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
  {
    try {
      // Malformed myFunc treated as (dynamic) => dynamic.
      Expect.isTrue(((int x) => x) is myFunc);
    } on TypeError catch (error) {
      Expect.fail();
    }
  }
  {
    try {
      // Malformed myFunc2 treated as (dynamic,int) => dynamic.
      Expect.isTrue(((int x, int y) => x) is myFunc2);
    } on TypeError catch (error) {
      Expect.fail();
    }
  }
  {
    try {
      // Malformed myFunc2 treated as (dynamic,int) => dynamic.
      Expect.isFalse(((int x, String y) => x) is myFunc2);
    } on TypeError catch (error) {
      Expect.fail();
    }
  }
}
