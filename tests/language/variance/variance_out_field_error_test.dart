// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous field usage for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class A<out T> {
  void set a(T value) => value;
  //         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //           ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
  final void Function(T) b = (T val) {};
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
  late T c;
//       ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
// [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  T? d = null;
  // ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}

mixin BMixin<out T> {
  void set a(T value) => value;
  //         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //           ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
  final void Function(T) b = (T val) {};
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
  late T c;
//       ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
// [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  T? d = null;
  // ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}

abstract class C<out T> {
  void set a(T value) => value;
  //         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //           ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}

class D<out T> extends C<T> {
  late var a;
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}
