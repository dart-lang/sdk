// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and enum shorthands with static members.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

void memberTest() {
  StaticMember member = StaticMember.member();

  // Warning when LHS is not able to be `null`.
  StaticMember memberLocal = .member() ?? member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  StaticMember memberType = .memberType<String, int>("s") ?? member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void memberExtTest() {
  StaticMemberExt<int> member = StaticMemberExt.member();

  // Warning when LHS is not able to be `null`.
  StaticMemberExt memberLocal = .member() ?? member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  StaticMemberExt memberType = .memberType<String, int>("s") ?? member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
