// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators
// with selector chains.

import '../dot_shorthand_helper.dart';

/// Every shorthand in [notSymmetrical] has the context type of `_` and won't
/// resolve.
void notSymmetrical(StaticMember member, ConstructorWithNonFinal ctor) {
  bool eqField = .member().field == member;
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqMethod = .member().method() == member;
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqMixed = .member().method().field == member;
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqMixed2 = .member().field.method() == member;
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqField = .member().field != member;
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqMethod = .member().method() != member;
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqMixed = .member().method().field != member;
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool neqMixed2 = .member().field.method() != member;
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  bool eqCtorField = .new(1).field == ctor;
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool eqCtorMethod = .new(1).method() == ctor;
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool eqCtorMixed = .new(1).method().field == ctor;
  //                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool eqCtorMixed2 = .new(1).field.method() == ctor;
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool neqCtorField = .new(1).field != ctor;
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool neqCtorMethod = .new(1).method() != ctor;
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool neqCtorMixed = .new(1).method().field != ctor;
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  bool neqCtorMixed2 = .new(1).field.method() != ctor;
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.member().field == member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().method() == member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().method().field == member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().field.method() == member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().field != member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().method() != member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().method().field != member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.member().field.method() != member) print('ok');
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'member'.

  if (.new(1).field == ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).method() == ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).method().field == ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).field.method() == ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).field != ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).method() != ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).method().field != ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.new(1).field.method() != ctor) print('ok');
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.
}

void rhsNeedsToBeShorthand(
  StaticMember member,
  ConstructorWithNonFinal ctor,
  bool condition,
) {
  if (member == (.member().field)) {
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member == (.member().method())) {
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member == (condition ? StaticMember.member() : .member().field)) {
    //                                                ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member == (condition ? StaticMember.member() : .member().method())) {
    //                                                ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member ==
      (condition
          ? StaticMember.member()
          : .member().method().field)) {
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member ==
      (condition
          ? StaticMember.member()
          : .member().field.method())) {
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member != (condition ? StaticMember.member() : .member().field)) {
    //                                                ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member != (condition ? StaticMember.member() : .member().method())) {
    //                                                ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member !=
      (condition
          ? StaticMember.member()
          : .member().method().field)) {
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (member !=
      (condition
          ? StaticMember.member()
          : .member().field.method())) {
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'member'.
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field)) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method())) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method().field)) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field.method())) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field)) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method())) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method().field)) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field.method())) {
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }
}

void objectContextType(StaticMember member, ConstructorWithNonFinal ctor) {
  if ((member as Object) == .member().field) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) == .member().method()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) == .member().method().field) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) == .member().field.method()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) != .member().field) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) != .member().method()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) != .member().method().field) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  if ((member as Object) != .member().field.method()) print('not ok');
  //                         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static method or constructor 'member' isn't defined for the type 'Object'.

  // The following shorthands have the context type of `Object` instead of 
  // `ConstructorWithNonFinal`.
  // Even though `Object` has a default constructor, it doesn't accept a
  // positional argument and furthermore, the rest of the chain will produce an
  // error since the constructor can't be resolved.

  if ((ctor as Object) == .new(1).field) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  if ((ctor as Object) == .new(1).method()) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD

  if ((ctor as Object) == .new(1).method().field) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD

  if ((ctor as Object) == .new(1).field.method()) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  if ((ctor as Object) != .new(1).field) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER

  if ((ctor as Object) != .new(1).method()) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD

  if ((ctor as Object) != .new(1).method().field) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD

  if ((ctor as Object) != .new(1).field.method()) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  //                              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
}
