// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for type checks involving the void type.

import "package:expect/expect.dart";

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

void f() {
  return;
}

void f_null() {
  return null;
}

void f_1() {
  return 1;
}

void f_dyn_null() {
  var x = null;
  return x;
}

void f_dyn_1() {
  var x = 1;
  return x;
}

void f_f() {
  return f();
}

void test(int n, void func()) {
  // Test as closure call.
  {
    bool got_type_error = false;
    try {
      var x = func();
    } on TypeError catch (error) {
      got_type_error = true;
    }
    Expect.isFalse(got_type_error);
  }
  // Test as direct call.
  {
    bool got_type_error = false;
    try {
      var x;
      switch (n) {
        case 0:
          x = f();
          break;
        case 1:
          x = f_null();
          break;
        case 2:
          x = f_1();
          break;
        case 3:
          x = f_dyn_null();
          break;
        case 4:
          x = f_dyn_1();
          break;
        case 5:
          x = f_f();
          break;
      }
    } on TypeError catch (error) {
      got_type_error = true;
    }
    Expect.isFalse(got_type_error);
  }
}

main() {
  test(0, f);
  test(1, f_null);
  test(2, f_1);
  test(3, f_dyn_null);
  test(4, f_dyn_1);
  test(5, f_f);
}
