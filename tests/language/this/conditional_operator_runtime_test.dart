// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the ?. operator cannot be used for forwarding "this"
// constructors.

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;

  B.forward();

  test() {
    this?.field = 1;
//  ^
// [cfe] The receiver 'this' cannot be null.
    //  ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    this?.field += 1;
//  ^
// [cfe] The receiver 'this' cannot be null.
    //  ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    this?.field;
//  ^
// [cfe] The receiver 'this' cannot be null.
    //  ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    this?.method();
//  ^
// [cfe] The receiver 'this' cannot be null.
    //  ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  }
}

main() {
  new B.forward().test();
}
