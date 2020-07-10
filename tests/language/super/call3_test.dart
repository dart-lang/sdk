// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing implicit super calls with bad arguments or no default
// constructor in super class.

import "package:expect/expect.dart";

class A {
  A(
    this.x
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD
//       ^
// [cfe] 'x' isn't an instance field of this class.
      );
  final foo = 499;
}

class B extends A {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.

class B2 extends A {
  B2();
//^^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  B2.named() : this.x = 499;
//^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  var x;
}

class C {
  C
  .named
  ();
  final foo = 499;
}

class D extends C {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'C', has no unnamed constructor that takes no arguments.

class D2 extends C {
  D2();
//^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER
// [cfe] The superclass, 'C', has no unnamed constructor that takes no arguments.
  D2.named() : this.x = 499;
//^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER
// [cfe] The superclass, 'C', has no unnamed constructor that takes no arguments.
  var x;
}

main() {
  Expect.equals(499, new B().foo);
  Expect.equals(499, new B2().foo);
  Expect.equals(499, new B2.named().foo);
  Expect.equals(499, new D().foo);
  Expect.equals(499, new D2().foo);
  Expect.equals(499, new D2.named().foo);
}
