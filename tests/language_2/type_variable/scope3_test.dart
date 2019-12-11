// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type parameter cannot be repeated.

class Foo<
    T
    , T
    //^
    // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
    // [cfe] A type variable can't have the same name as another.
    > {}

main() {
  new Foo<
      String
      , String
      >();
}
