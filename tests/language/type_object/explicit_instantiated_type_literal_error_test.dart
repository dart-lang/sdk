// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



// Tests that explicitly instantiated type objects only work
// when instantiated correctly.

class C<T extends num> {}

void use(Type type) {}

void main() {
  use(C<Object>);
  //  ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'T' on 'C'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  use(C<int, int>);
  //  ^
  // [cfe] Expected 1 type arguments.
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS

  use(C<>);
  //    ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
  // [cfe] Expected a type, but got '>'.
  // [cfe] This couldn't be parsed.
}
