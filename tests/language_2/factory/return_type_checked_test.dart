// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  factory A() => 42;
  //             ^^
  // [analyzer] STATIC_TYPE_WARNING.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'A'.
}

main() {
  Expect.throws(() => new A());
}
