// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var x;
  f() {}

  testMe() {
    x.this; //# 01: compile-time error
    x.this(); //# 02: compile-time error
    x.this.x; //# 03: compile-time error
    x.this().x; //# 04: compile-time error
    f().this; //# 05: compile-time error
    f().this(); //# 06: compile-time error
    f().this.f(); //# 07: compile-time error
    f().this().f(); //# 08: compile-time error
  }
}

main() {
  new Foo().testMe();
}
