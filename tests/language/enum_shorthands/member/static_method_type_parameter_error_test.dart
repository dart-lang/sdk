// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors when the type parameters of the shorthand methods don't match the
// context type.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

void main() {
  StaticMember<bool> s = .member();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  StaticMember<int> sTypeParameters = .memberType("s");
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  StaticMemberExt<bool> sExt = .member();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  StaticMemberExt<int> sTypeParametersExt = .memberType("s");
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
