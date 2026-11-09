// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous member signatures, `with` and `implements` superinterfaces,
// and subtyping assignments for enums with `out`, `in`, and `inout` variance
// modifiers.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class Contravariant<in T> {}

mixin MCovariant<out T> {}

mixin MInvariant<inout T> {}

enum OutParameter<out T> {
  a;

  void method(T x) {}
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}

enum InReturn<in T> {
  a;

  T? get value => null;
//^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
//       ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
}

enum OutImplements<out T> implements Contravariant<T> { a }
//   ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//                     ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

enum OutWith<out T> with MInvariant<T> { a }
//   ^
// [cfe] Can't use 'out' type variable 'T' in an 'inout' position in supertype 'MInvariant'.
//               ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

enum InImplements<in T> implements Covariant<T> { a }
//   ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//                   ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

enum InWith<in T> with MCovariant<T> { a }
//   ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MCovariant'.
//             ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

enum OutEnum<out T> { a }

enum InEnum<in T> { a }

enum InoutEnum<inout T> { a }

void subtyping(
  OutEnum<num> outValue,
  InEnum<int> inValue,
  InoutEnum<int> inoutValue,
) {
  OutEnum<int> outInt = outValue;
  //                    ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'OutEnum<num>' can't be assigned to a variable of type 'OutEnum<int>'.

  InEnum<num> inNum = inValue;
  //                  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'InEnum<int>' can't be assigned to a variable of type 'InEnum<num>'.

  InoutEnum<num> inoutNum = inoutValue;
  //                        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'InoutEnum<int>' can't be assigned to a variable of type 'InoutEnum<num>'.
}
