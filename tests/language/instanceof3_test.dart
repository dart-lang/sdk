// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

// In the type test 'e is T', it is a run-time error if T does not denote a type
// available in the current lexical scope.

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch(var e) {
    return true;
  }
}

testAll() {
  {
    bool got_type_error = false;
    var x = null;
    try {
      Expect.isFalse(x is UndeclaredType);  // x is null.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in production mode and in checked mode.
    Expect.isTrue(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = 1;
    try {
      Expect.isFalse(x is UndeclaredType);  // x is not null.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in production mode and in checked mode.
    Expect.isTrue(got_type_error);
  }
  {
    bool got_type_error = false;
    var x = null;
    try {
      Expect.isFalse(x is List<UndeclaredType>);  // x is null.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
  {
    bool got_type_error = false;
    var x = 1;
    try {
      Expect.isFalse(x is List<UndeclaredType>);  // x is not a List.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
  {
    bool got_type_error = false;
    var x = new List();
    try {
      Expect.isTrue(x is List<UndeclaredType>);  // x is a List<Dynamic>.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
  {
    bool got_type_error = false;
    var x = new List<int>();
    try {
      Expect.isTrue(x is List<UndeclaredType>);  // x is a List<int>.
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());
  }
}

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    testAll();
  }
}
