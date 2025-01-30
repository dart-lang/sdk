// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators
// with selector chains.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

/// Every shorthand in [notSymmetrical] has the context type of `_` and won't
/// resolve.
void notSymmetrical(StaticMember member, ConstructorWithNonFinal ctor) {
  bool eqField = .member().field == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqMethod = .member().method() == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqMixed = .member().method().field == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool eqMixed2 = .member().field.method() == member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqField = .member().field != member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqMethod = .member().method() != member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqMixed = .member().method().field != member;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  bool neqMixed2 = .member().field.method() != member;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool eqCtorField = .new(1).field == ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool eqCtorMethod = .new(1).method() == ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool eqCtorMixed = .new(1).method().field == ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool eqCtorMixed2 = .new(1).field.method() == ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool neqCtorField = .new(1).field != ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool neqCtorMethod = .new(1).method() != ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool neqCtorMixed = .new(1).method().field != ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  bool neqCtorMixed2 = .new(1).field.method() != ctor;
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().field == member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().method() == member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().method().field == member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().field.method() == member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().field != member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().method() != member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().method().field != member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.member().field.method() != member) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).field == ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).method() == ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).method().field == ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).field.method() == ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).field != ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).method() != ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).method().field != ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]

  if (.new(1).field.method() != ctor) print('ok');
  // ^
  // [analyzer] unspecified
  // [cfe]
}

void rhsNeedsToBeShorthand(
  StaticMember member,
  ConstructorWithNonFinal ctor,
  bool condition,
) {
  if (member == (condition ? StaticMember.member() : .member().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member == (condition ? StaticMember.member() : .member().method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member ==
      (condition
          ? StaticMember.member()
          : .member().method().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member ==
      (condition
          ? StaticMember.member()
          : .member().field.method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member != (condition ? StaticMember.member() : .member().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member != (condition ? StaticMember.member() : .member().method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member !=
      (condition
          ? StaticMember.member()
          : .member().method().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (member !=
      (condition
          ? StaticMember.member()
          : .member().field.method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor ==
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field.method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).method().field)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor !=
      (condition
          ? ConstructorWithNonFinal(1)
          : .new(1).field.method())) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
}

void objectContextType(StaticMember member, ConstructorWithNonFinal ctor) {
  if ((member as Object) == .member().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) == .member().method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) == .member().method().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) == .member().field.method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .member().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .member().method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .member().method().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((member as Object) != .member().field.method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // The following shorthands have the context type of `Object` instead of 
  // `ConstructorWithNonFinal`.
  // Even though `Object` has a default constructor, it doesn't accept a
  // positional argument and furthermore, the rest of the chain will produce an
  // error since the constructor can't be resolved.

  if ((ctor as Object) == .new(1).field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .new(1).method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .new(1).method().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .new(1).field.method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .new(1).field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .new(1).method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .new(1).method().field) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .new(1).field.method()) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
