// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that '??' binds tighter than '?:' and less tightly than '||'.

import "package:expect/expect.dart";

main() {
  // Make sure the "none" test fails if "??" is not implemented.  This makes
  // status files easier to maintain.
  var _ = null ?? null;

  dynamic falsity = false;
  dynamic truth = true;
  dynamic one = 1;
  dynamic two = 2;

  // "a ?? b ?? c" should be legal, and should evaluate to the first non-null
  // value (or null if there are no non-null values).
  Expect.equals(1, one ?? two ?? 3);
  Expect.equals(2, null ?? two ?? 3);
  Expect.equals(3, null ?? null ?? 3);
  Expect.equals(null, null ?? null ?? null);

  // "a ?? b ? c : d" should parse as "(a ?? b) ? c : d", therefore provided
  // that a is true, b need not be a bool.  An incorrect parse of
  // "a ?? (b ? c : d)" would require b to be a bool to avoid a static type
  // warning.
  Expect.equals(2, truth ?? 1 ? 2 : 3);

  // "a ?? b || c" should parse as "a ?? (b || c)", therefore it's a static
  // type warning if b doesn't have type bool.  An incorrect parse of
  // "(a ?? b) || c" would allow b to have any type provided that a is bool.
  falsity ?? 1 || true;
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.

  // "a || b ?? c" should parse as "(a || b) ?? c", therefore it is a static
  // type warning if b doesn't have type bool.  An incorrect parse of
  // "a || (b ?? c)" would allow b to have any type provided that c is bool.
  falsity || 1 ?? true;
//        ^
// [cfe] Operand of null-aware operation '??' has type 'bool' which excludes null.
//           ^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
//                ^^^^
// [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  // An incorrect parse of "a || (b ?? c)" would result in no checked-mode
  // error.
  Expect.throwsAssertionError(() => false || null ?? true);
  //                                      ^
  // [cfe] Operand of null-aware operation '??' has type 'bool' which excludes null.
  //                                         ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
  // [cfe] The value 'null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
  //                                                 ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}
