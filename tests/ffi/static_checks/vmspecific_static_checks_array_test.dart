// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

// dart format off

import 'dart:ffi';

void main() {}

final class TestStruct1 extends Struct {
  /**/ @Array.variable()
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Uint8>> a0;
  //                           ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.
}

final class TestStruct2 extends Struct {
  /**/ @Array.variable()
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VARIABLE_LENGTH_ARRAY_NOT_LAST
  external Array<Uint8> a0;
  //                    ^
  // [cfe] Variable length 'Array's must only occur as the last field of Structs.

  @Uint8()
  external int a1;
}

final class TestStruct3 extends Struct {
  // This should be a Array.variable() not an `@Array(0)`.
  @Array(0)
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.NON_POSITIVE_ARRAY_DIMENSION
  external Array<Uint8> a0;
  //                    ^^
  // [cfe] Array dimensions must be positive numbers.
}

final class TestStruct4 extends Struct {
  /**/ @Array.variable(1, 2)
  //   ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Uint8>> a0;
  //                           ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.
}

final class TestStruct5 extends Struct {
  /**/ @Array.variableMulti([1, 2])
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Uint8>> a0;
  //                           ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.
}

final class TestStruct6 extends Struct {
  @Array.variableMulti([1, 2])
  external Array<Array<Array<Uint8>>> a0;
}

final class TestStruct7 extends Struct {
  /**/ @Array.variableMulti([1, 2])
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Array<Array<Uint8>>>> a0;
  //                                         ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.
}

final class TestStruct8 extends Struct {
  /**/ @Array.variable()
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VARIABLE_LENGTH_ARRAY_NOT_LAST
  external Array<Uint8> a0;
  //                    ^
  // [cfe] Variable length 'Array's must only occur as the last field of Structs.

  @Uint8()
  external int get a1;
}

final class TestStruct9 extends Struct {
  /**/ @Array.variable()
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VARIABLE_LENGTH_ARRAY_NOT_LAST
  external Array<Uint8> a0;
  //                    ^
  // [cfe] Variable length 'Array's must only occur as the last field of Structs.

  @Uint8()
  external int get a1;
  external set a1(int value);
}

final class TestStruct10 extends Struct {
  @Array.variable()
  external Array<Uint8> a0;

  bool get a1 => true;
}

final class TestStruct11 extends Struct {
  @Array.variable()
  external Array<Uint8> a0;

  set a1(bool value) {}
}

final class TestStruct12 extends Struct {
  @Array.variable()
  external Array<Uint8> a0;

  bool get a1 => true;
  set a1(bool value) {}
}
