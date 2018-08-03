// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance field cannot be read as a static field.

class Foo {
  Foo() {}
  var x;
  void m() {}
}

main() {
  if (false) {
    var x = Foo.x; // //# 01: compile-time error
    var m = Foo.m; // //# 02: compile-time error
    Foo.m = 1; // //# 03: compile-time error
    Foo.x = 1; // //# 04: compile-time error
  }
}
