// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for type checks involving the void type.

import "package:expect/expect.dart";

void f() {
  return;
}

void f_null() {
  return null;
}

void f_dyn_null() {
  return null as dynamic;
}

void f_f() {
  return f();
}

void test(int n, void func(), bool must_get_error) {
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
          x = f_dyn_null();
          break;
        case 3:
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
  test(0, f, false);
  test(1, f_null, false);
  test(2, f_dyn_null, false);
  test(3, f_f, false);
}
