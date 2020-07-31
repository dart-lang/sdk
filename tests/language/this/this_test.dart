// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var x;
  f() {}

  testMe() {
    x.this;
    //^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    x.this();
    //^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    x.this.x;
    //^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    x.this().x;
    //^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    f().this;
    //  ^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    f().this();
    //  ^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    f().this.f();
    //  ^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
    f().this().f();
    //  ^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
    // [cfe] Expected identifier, but got 'this'.
  }
}

main() {
  new Foo().testMe();
}
