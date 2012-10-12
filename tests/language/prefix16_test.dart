// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved imported symbols are handled differently in production mode and
// check modes. In this test, the function myFunc is malformed, because
// lib12.Library13 is not resolved.
// In checked mode, the assignment type check throws a run time type error.
// In production, no assignment type checks are performed.

#library("Prefix16NegativeTest.dart");
#import("library12.dart", prefix:"lib12");

typedef lib12.Library13 myFunc(lib12.Library13 param);

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
      myFunc i = 0;
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
  {
    bool got_type_error = false;
    try {
      // In production mode, malformed myFunc is mapped to (dynamic) => dynamic.
      Expect.isTrue(((int x) => x) is myFunc);
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
}
