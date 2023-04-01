// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

main() {
  var local = 'local';

  // If cases sharing a body don't agree on a variable's finality, it is still
  // considered in scope and an error to use.
  switch ('value') {
    case final int local when false: // Guard to make the next case reachable.
      //           ^^^^^
      // [cfe] unspecified
    case int local:
      print(local);
      //    ^^^^^
      // [analyzer] unspecified
  }

  // If cases sharing a body don't agree on a variable's type, it is still
  // considered in scope and an error to use.
  switch ('value') {
    case bool local:
      //      ^^^^^
      // [cfe] unspecified
    case int local:
      print(local);
      //    ^^^^^
      // [analyzer] unspecified
  }
}
