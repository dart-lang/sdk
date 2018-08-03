// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var x;
  f() {}

  testMe() {
    x.this; //# 01: syntax error
    x.this(); //# 02: syntax error
    x.this.x; //# 03: syntax error
    x.this().x; //# 04: syntax error
    f().this; //# 05: syntax error
    f().this(); //# 06: syntax error
    f().this.f(); //# 07: syntax error
    f().this().f(); //# 08: syntax error
  }
}

main() {
  new Foo().testMe();
}
