// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we infer `Object?` for an extension type's representation type if
// the type isn't specified.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/static_type_helper.dart';

// Representation type is `Object?`, not `dynamic`.
extension type ET3(i);

void main() {
  var et3 = ET3(1);
  // Would be valid if type was `dynamic`.
  if (1 > 2) et3.i.arglebargle;
  //               ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] unspecified

  ET0(null).name.expectStaticType<Exactly<Object?>>();
}

abstract interface class A {
  A get name;
}

// No inheritance inference of the `name` property.

// Error because default representation type `Object?` is not <: `A`.
extension type ET2(name) implements A {}
//                                  ^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE
// [cfe] The implemented interface 'A' must be a supertype of the representation type 'Object?' of extension type 'ET2'.

extension type ES1(int? _) {
  int? get name => 0;
}

// Error because default representation type `Object?` is not <: `int?`.
extension type ET1(name) implements ES1 {}
//                                  ^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE
// [cfe] The representation type 'Object?' of extension type 'ET1' must be either a subtype of the representation type 'int?' of the implemented extension type 'ES1' or a subtype of 'ES1' itself.

extension type ES0(Object? _) {
  int? get name => 0;
}

// No error, default type of `Object?` is valid for `ES0` too.
extension type ET0(name) implements ES0 {}
