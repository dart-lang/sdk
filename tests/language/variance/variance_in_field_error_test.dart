// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous field usage for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class A<in T> {
  final T a = throw "uncalled";
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  final T Function() b = () => throw "uncalled";
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T get c => throw "uncalled";
//^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
//        ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  late T d;
//       ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
// [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  covariant late T e;
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T? f = null;
  // ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
}

mixin BMixin<in T> {
  final T a = throw "uncalled";
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  final T Function() b = () => throw "uncalled";
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T get c => throw "uncalled";
//^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
//        ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  late T d;
//       ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
// [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  covariant late T e;
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  T? f = null;
  // ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
}

abstract class C<in T> {
  T get a;
//^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
//       ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
}

class D<in T> extends C<T> {
  var a;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Field 'a' should be initialized because its type 'T' doesn't allow null.
}
