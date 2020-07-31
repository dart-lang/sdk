// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check type bounds when invoking a redirecting factory method

abstract class Foo {}

abstract class IA<T> {
  factory IA() = A<T>;
  //             ^
  // [cfe] The type 'T' doesn't extend 'Foo'.
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

class A<T extends Foo> implements IA<T> {
  factory A() { return A._(); }

  A._();
}

main() {
  var result = new IA<String>();
  //               ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'Foo' of the type variable 'T' on 'A'.
}
