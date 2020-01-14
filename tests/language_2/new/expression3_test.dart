// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {}

main() {
  new C(...;
  //   ^
  // [cfe] Can't find ')' to match '('.
  //   ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
  //    ^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got '...'.
  //       ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
}
