// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators
// for static members.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void notSymmetrical(StaticMember member, StaticMemberExt memberExt) {
  bool eq = .member() == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqType = .memberType<String, int>('s') == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neq = .member() != member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqType = .memberType<String, int>('s') != member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqExt = .member() == memberExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqTypeExt = .memberType<String, int>('s') == memberExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqExt = .member() != memberExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqTypeExt = .memberType<String, int>('s') != memberExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.member() == member) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.memberType<String, int>('s') == member) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.member() != member) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.memberType<String, int>('s') != member) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.member() == memberExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.memberType<String, int>('s') == memberExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.member() != memberExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.memberType<String, int>('s') != memberExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void rhsNeedsToBeShorthand(
  StaticMember member,
  StaticMemberExt memberExt,
  bool condition,
) {
  if (member == (condition ? .member() : .memberType<String, int>('s'))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member != (condition ? .member() : .memberType<String, int>('s'))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (memberExt == (condition ? .member() : .memberType<String, int>('s'))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (memberExt != (condition ? .member() : .memberType<String, int>('s'))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
}

void objectContextType(StaticMember member, StaticMemberExt memberExt) {
  if ((member as Object) == .member()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) == .memberType<String, int>('s')) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .member()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .memberType<String, int>('s')) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((memberExt as Object) == .member()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((memberExt as Object) == .memberType<String, int>('s')) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((memberExt as Object) != .member()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((memberExt as Object) != .memberType<String, int>('s')) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void main() {
  StaticMember member = .member();
  StaticMemberExt memberExt = .member();

  notSymmetrical(member, memberExt);
  rhsNeedsToBeShorthand(member, memberExt, true);
  rhsNeedsToBeShorthand(member, memberExt, false);
  objectContextType(member, memberExt);
}
