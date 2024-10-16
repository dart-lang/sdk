// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that a null check in a guard expression causes promotion.

import 'package:expect/expect.dart';

import 'package:expect/static_type_helper.dart';

bool inSwitchStatement(x) {
  switch (x) {
    case int? y when y != null:
      y.expectStaticType<Exactly<int>>();
      return true;
    default:
      return false;
  }
}

bool inSwitchExpression(x) => switch (x) {
      int? y when y != null => [y.expectStaticType<Exactly<int>>()].isNotEmpty,
      _ => false
    };

bool inIfCaseStatement(x) {
  if (x case int? y when y != null) {
    y.expectStaticType<Exactly<int>>();
    return true;
  } else {
    return false;
  }
}

bool inIfCaseElementInList(x) => [
      if (x case int? y when y != null) y.expectStaticType<Exactly<int>>()
    ].isNotEmpty;

bool inIfCaseElementInMap(x) => {
      if (x case int? y when y != null) '': y.expectStaticType<Exactly<int>>()
    }.isNotEmpty;

bool inIfCaseElementInSet(x) => {
      if (x case int? y when y != null) y.expectStaticType<Exactly<int>>()
    }.isNotEmpty;

main() {
  Expect.equals(true, inSwitchStatement(0));
  Expect.equals(false, inSwitchStatement(null));
  Expect.equals(false, inSwitchStatement(''));
  Expect.equals(true, inSwitchExpression(0));
  Expect.equals(false, inSwitchExpression(null));
  Expect.equals(false, inSwitchExpression(''));
  Expect.equals(true, inIfCaseStatement(0));
  Expect.equals(false, inIfCaseStatement(null));
  Expect.equals(false, inIfCaseStatement(''));
  Expect.equals(true, inIfCaseElementInList(0));
  Expect.equals(false, inIfCaseElementInList(null));
  Expect.equals(false, inIfCaseElementInList(''));
  Expect.equals(true, inIfCaseElementInMap(0));
  Expect.equals(false, inIfCaseElementInMap(null));
  Expect.equals(false, inIfCaseElementInMap(''));
  Expect.equals(true, inIfCaseElementInSet(0));
  Expect.equals(false, inIfCaseElementInSet(null));
  Expect.equals(false, inIfCaseElementInSet(''));
}
