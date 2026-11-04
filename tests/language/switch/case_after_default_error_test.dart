// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a `case` following a `default` case is reported as an error, and
// that the cases following the `default` case aren't treated as if they also
// contained the `default` case (which would cause spurious errors about
// pattern variables not being available).

void patternCaseAfterDefault(Object o) {
  switch (o) {
    default:
      print('default');
    case int x:
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
// [cfe] The default case should be the last case in a switch statement.
      print(x);
  }
}

void multiplePatternCasesAfterDefault(Object o) {
  switch (o) {
    default:
      print('default');
    case int x:
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
// [cfe] The default case should be the last case in a switch statement.
      print(x);
    case String x:
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
// [cfe] The default case should be the last case in a switch statement.
      print(x);
  }
}

void constantCaseAfterDefault(int a) {
  switch (a) {
    default:
      print('default');
    case 1:
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
// [cfe] The default case should be the last case in a switch statement.
      print('one');
  }
}

main() {
  patternCaseAfterDefault(0);
  multiplePatternCasesAfterDefault(0);
  constantCaseAfterDefault(0);
}
