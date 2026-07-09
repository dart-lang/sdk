// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var local = 'local';

  // If cases sharing a body don't agree on a variable's finality, it is still
  // considered in scope and an error to use.
  switch ('value') {
    case final int local when false: // Guard to make the next case reachable.
    case int local:
      print(local);
    //      ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
    // [cfe] Variable pattern 'local' doesn't have the same type or finality in all cases.
  }

  // If cases sharing a body don't agree on a variable's type, it is still
  // considered in scope and an error to use.
  switch ('value') {
    case bool local:
    case int local:
      print(local);
    //      ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
    // [cfe] Variable pattern 'local' doesn't have the same type or finality in all cases.
  }
}
