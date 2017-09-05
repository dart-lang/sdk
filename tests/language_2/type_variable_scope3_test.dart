// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type parameter cannot be repeated.

class Foo<
    T
    , T // //# 00: compile-time error
    > {}

main() {
  new Foo<
      String
      , String // //# 00: continued
      >();
}
