// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that malformed type arguments are reported in checked mode.

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch(var e) {
    return true;
  }
}

class Foo<T> {
  // T is not in scope for a static method.
  static Foo<T> m() {
    return new Foo();
  }
}

main() {
  bool got_type_error = false;
  try {
    Expect.isTrue(Foo.m() is Foo);
  } catch (TypeError error) {
    got_type_error = true;
  }
  // Type error in checked mode only.
  Expect.isTrue(got_type_error == isCheckedMode());
}
