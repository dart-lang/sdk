// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the parser emits an error when one 'is' expression follows
/// another.
class A {}

main() {
  var a = A();
  if (a is A is A) return 0;
  //         ^^
  // [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
  // [cfe] Unexpected token 'is'.
}
