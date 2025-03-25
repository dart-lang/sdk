// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors when having the wrong type parameters and using type parameters in
// `.new` or `.new()`.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void main() {
  StaticMember<int> s = .memberType<String, String>('s');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Constructors doesn't have type parameters.
  StaticMember<int> constructorTypeParameter = .constNamed<int>(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // `.new<type-args>()` and `.new<type-args>` are a compile-time error.
  UnnamedConstructorTypeParameters typeParameters = .new<int>();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  UnnamedConstructorTypeParameters Function() tearOff = .new<int>;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
