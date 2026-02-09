// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and dot shorthands with static members.

import '../dot_shorthand_helper.dart';

extension type IfNullExt<T extends num>(T x) implements num {
  static IfNullExt<int> member() => IfNullExt(1);
  static IfNullExt<U> memberType<U extends num, V>(U u) => IfNullExt(u);
}

void memberTest() {
  StaticMember member = StaticMember.member();

  // Warning when LHS is not able to be `null`.
  StaticMember memberLocal = .member() ?? member;
  //                                      ^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  StaticMember memberType = .memberType<String, int>("s") ?? member;
  //                                                         ^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}

void memberExtTest() {
  IfNullExt<int> member = IfNullExt.member();

  // Warning when LHS is not able to be `null`.
  IfNullExt memberLocal = .member() ?? member;
  //                                   ^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  IfNullExt memberType = .memberType<int, String>(1) ?? member;
  //                                                    ^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}

void main() {
  memberTest();
  memberExtTest();
}
