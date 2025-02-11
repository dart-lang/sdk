// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and dot shorthands with constructors.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void constructorClassTest() {
  ConstructorClass ctor = ConstructorClass(1);

  // Warning when LHS is not able to be `null`.
  ConstructorClass notNullable = .new(1) ?? ctor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorClass notNullableRegular = .regular(1) ?? ctor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorClass notNullableNamed = .named(x: 1) ?? ctor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorClass notNullableOptional = .optional(1) ?? ctor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void constructorExtTest() {
  ConstructorExt ctorExt = ConstructorExt(1);

  // Warning when LHS is not able to be `null`.
  ConstructorExt notNullableExt = .new(1) ?? ctorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorExt notNullableRegularExt = .regular(1) ?? ctorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorExt notNullableNamedExt = .named(x: 1) ?? ctorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  ConstructorExt notNullableOptionalExt = .optional(1) ?? ctorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
