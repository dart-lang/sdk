// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Test that we expect a class after an 'is'.
class A {}

main() {
  var a = A();
  if (a is "A") return 0;
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
  // [cfe] Expected ')' before this.
  // [cfe] Expected a type, but got '"A"'.
  // [cfe] This couldn't be parsed.
}
