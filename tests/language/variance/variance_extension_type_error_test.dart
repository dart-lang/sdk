// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous representation types, `implements` superinterfaces, usage in
// class member signatures, and subtyping assignments for extension types with
// `out`, `in`, and `inout` variance modifiers.

// SharedOptions=--enable-experiment=variance

extension type Covariant<out X>(Object? base) {}

extension type Contravariant<in X>(Object? base) {}

extension type OutFunctionParameter<out T>(void Function(T) function) {}
//                                                       ^
// [analyzer] unspecified
// [cfe] unspecified

extension type InRepresentationType<in T>(T it) {}
//                                        ^
// [analyzer] unspecified
// [cfe] unspecified

extension type OutImplements<out T>(Object? it) implements Contravariant<T> {}
//                                                                       ^
// [analyzer] unspecified
// [cfe] unspecified

extension type InImplements<in T>(Object? it) implements Covariant<T> {}
//                                                                 ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class OutSignature<out T> {
  Contravariant<T> get value;
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

abstract class InSignature<in T> {
  void method(Contravariant<T> x);
  //                        ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type OutRepresentation<out T>(T it) {}

extension type InRepresentation<in T>(void Function(T) function) {}

extension type InoutRepresentation<inout T>(T Function(T) function) {}

void subtyping(
  OutRepresentation<num> outValue,
  InRepresentation<int> inValue,
  InoutRepresentation<int> inoutValue,
) {
  OutRepresentation<int> outInt = outValue;
  //                              ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  InRepresentation<num> inNum = inValue;
  //                            ^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  InoutRepresentation<num> inoutNum = inoutValue;
  //                                  ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}
