// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that the analyzer's UNREACHABLE_SWITCH_CASE is properly fired when
// the switch case has a `when` clause.

enum E { e1, e2 }

Object reachableCaseInSwitchExpression(E e, bool b) => switch (e) {
      E.e1 when b => 0,
      E.e2 => 1,
      E.e1 => 2,
    };

Object unreachableCaseInSwitchExpression(E e, bool b) => switch (e) {
      E.e1 => 0,
      E.e2 => 1,
      E.e1 when b => 2,
      //          ^^
      // [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
    };

void reachableCaseInSwitchStatement(E e, bool b) {
  switch (e) {
    case E.e1 when b:
      break;
    case E.e2:
      break;
    case E.e1:
      break;
  }
}

void unreachableCaseInSwitchStatement(E e, bool b) {
  switch (e) {
    case E.e1:
      break;
    case E.e2:
      break;
    case E.e1 when b:
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      break;
  }
}

main() {}
