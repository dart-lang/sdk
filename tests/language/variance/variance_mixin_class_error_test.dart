// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous member signatures, `implements` superinterfaces, mixin
// applications, and subtyping assignments for mixin classes with `out`, `in`,
// and `inout` variance modifiers.

// SharedOptions=--enable-experiment=variance

class Contravariant<in T> {}

class Invariant<inout T> {}

mixin class OutParameter<out T> {
  void method(T x) {}
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}

mixin class InReturn<in T> {
  T? get value => null;
//^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
//       ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
}

mixin class OutImplements<out T> implements Contravariant<T> {}
//          ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//                            ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

mixin class InImplements<in T> implements Invariant<T> {}
//          ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//                          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

mixin class OutMixinClass<out T> {}

mixin class InMixinClass<in T> {}

mixin class InoutMixinClass<inout T> {}

class OutWithIn<out T> with InMixinClass<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'InMixinClass'.
//                  ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

void subtyping(
  OutMixinClass<num> outValue,
  InMixinClass<int> inValue,
  InoutMixinClass<int> inoutValue,
) {
  OutMixinClass<int> outInt = outValue;
  //                          ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'OutMixinClass<num>' can't be assigned to a variable of type 'OutMixinClass<int>'.

  InMixinClass<num> inNum = inValue;
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'InMixinClass<int>' can't be assigned to a variable of type 'InMixinClass<num>'.

  InoutMixinClass<num> inoutNum = inoutValue;
  //                              ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'InoutMixinClass<int>' can't be assigned to a variable of type 'InoutMixinClass<num>'.
}
