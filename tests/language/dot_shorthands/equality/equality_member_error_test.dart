// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators
// for static members.

import '../dot_shorthand_helper.dart';

void notSymmetrical(StaticMember member, StaticMemberExt memberExt) {
  bool eq = .member() == member;
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqType = .memberType<String, int>('s') == member;
  //             ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  bool neq = .member() != member;
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqType = .memberType<String, int>('s') != member;
  //              ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  bool eqExt = .member() == memberExt;
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqTypeExt = .memberType<String, int>('s') == memberExt;
  //                ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  bool neqExt = .member() != memberExt;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqTypeExt = .memberType<String, int>('s') != memberExt;
  //                 ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  if (.member() == member) print('not ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.memberType<String, int>('s') == member) print('not ok');
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  if (.member() != member) print('not ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.memberType<String, int>('s') != member) print('not ok');
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  if (.member() == memberExt) print('not ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.memberType<String, int>('s') == memberExt) print('not ok');
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.

  if (.member() != memberExt) print('not ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.memberType<String, int>('s') != memberExt) print('not ok');
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'memberType'.
}

void rhsNeedsToBeShorthand(
  StaticMember member,
  StaticMemberExt memberExt,
  bool condition,
) {
  if (member == (.member())) {
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member != (.member())) {
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member == (condition ? .member() : .memberType<String, int>('s'))) {
    //                        ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    //                                    ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'memberType'.
    print('not ok');
  }

  if (member != (condition ? .member() : .memberType<String, int>('s'))) {
    //                        ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    //                                    ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'memberType'.
    print('not ok');
  }

  if (memberExt == (condition ? .member() : .memberType<String, int>('s'))) {
    //                           ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    //                                       ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'memberType'.
    print('not ok');
  }

  if (memberExt != (condition ? .member() : .memberType<String, int>('s'))) {
    //                           ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    //                                       ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'memberType'.
    print('not ok');
  }
}

void objectContextType(StaticMember member, StaticMemberExt memberExt) {
  if ((member as Object) == .member()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) == .memberType<String, int>('s')) print('not ok');
  //                         ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'memberType' isn't defined for the type 'Object'.

  if ((member as Object) != .member()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) != .memberType<String, int>('s')) print('not ok');
  //                         ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'memberType' isn't defined for the type 'Object'.

  if ((memberExt as Object) == .member()) print('not ok');
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((memberExt as Object) == .memberType<String, int>('s')) print('not ok');
  //                            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'memberType' isn't defined for the type 'Object'.

  if ((memberExt as Object) != .member()) print('not ok');
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((memberExt as Object) != .memberType<String, int>('s')) print('not ok');
  //                            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'memberType' isn't defined for the type 'Object'.
}

void main() {
  StaticMember member = .member();
  StaticMemberExt memberExt = .member();

  notSymmetrical(member, memberExt);
  rhsNeedsToBeShorthand(member, memberExt, true);
  rhsNeedsToBeShorthand(member, memberExt, false);
  objectContextType(member, memberExt);
}
