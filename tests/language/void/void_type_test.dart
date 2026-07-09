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

void test(int n, void func()) {
  // Test as closure call.
  {
    bool got_type_error = false;
    try {
      func();
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
          x = f() as dynamic;
          break;
        case 1:
          x = f_null() as dynamic;
          break;
        case 2:
          x = f_dyn_null() as dynamic;
          break;
        case 3:
          x = f_f() as dynamic;
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
  test(2, f_dyn_null);
  test(3, f_f);
}
