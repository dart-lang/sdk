// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T extends num> {}

class B<T> {
  test() {
    new A() is A
    //      ^
    // [cfe] Type argument 'T' doesn't conform to the bound 'num' of the type variable 'T' on 'A'.
        <T>
//       ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
        ;
  }
}

main() {
  var b = new B<String>();
  b.test();
}
