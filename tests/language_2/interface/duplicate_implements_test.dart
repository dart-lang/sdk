// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that duplicate types in implements/extends list are
// compile-time errors.

abstract class I {}

abstract class J {}

abstract class K<T> {}

class X implements I, J, I { } //              //# 01: compile-time error
class X implements J, I, K<int>, K<int> { } // //# 02: compile-time error

abstract class Z implements I, J, J { } //             //# 03: compile-time error
abstract class Z implements K<int>, K<int> { } //      //# 04: compile-time error

main() {
  X x = new X(); // //# 01: continued
  X x = new X(); // //# 02: continued
  Z z = new Z(); // //# 03: continued
  Z z = new Z(); // //# 04: continued
}
