// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

/// A variable declared by a pattern is in scope in the pattern but can't be
/// used in constant expression inside the pattern.

void testSwitchStatement(int x) {
  switch (x) {
    case var a && == a:
      //               ^
      // [analyzer] unspecified
      // [cfe] unspecified
      'error';
    case == b && var b:
      //    ^
      // [analyzer] unspecified
      // [cfe] unspecified
      'error';
  }
}

void testSwitchStatementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  switch (x) {
    case var a && == a:
      //             ^
      // [analyzer] unspecified
      // [cfe] unspecified
      'error';
    case == b && var b:
      //    ^
      // [analyzer] unspecified
      // [cfe] unspecified
      'error';
  }
}

String testSwitchExpression(int x) {
  return switch (x) {
    var a && == a => 'error',
    //          ^
    // [analyzer] unspecified
    // [cfe] unspecified
    == b && var b => 'error',
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    _ => 'other'
  };
}

String testSwitchExpressionInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  return switch (x) {
    var a && == a => 'error',
    //          ^
    // [analyzer] unspecified
    // [cfe] unspecified
    == b && var b => 'error',
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    _ => 'other'
  };
}

void testIfCaseStatement(int x) {
  if (x case var a && == a) {}
  //                     ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (x case == b && var b) {}
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void testIfCaseStatementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  if (x case var a && == a) {}
  //                     ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (x case == b && var b) {}
  //            ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

List<String> testIfCaseElement(int x) {
  return [
    if (x case var a && == a) 'one',
    //                     ^
    // [analyzer] unspecified
    // [cfe] unspecified
    if (x case == b && var b) 'two'
    //            ^
    // [analyzer] unspecified
    // [cfe] unspecified
  ];
}

List<String> testIfCaseElementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  return [
    if (x case var a && == a) 'one',
    //                     ^
    // [analyzer] unspecified
    // [cfe] unspecified
    if (x case == b && var b) 'two'
    //            ^
    // [analyzer] unspecified
    // [cfe] unspecified
  ];
}
