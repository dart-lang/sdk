// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that a getter has no parameters.

// @dart = 2.9

get f1 => null;
get f2
()
// [error line 11, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.GETTER_WITH_PARAMETERS
// [cfe] A getter can't have formal parameters.
    => null;
get f3
(arg)
// [error line 17, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.GETTER_WITH_PARAMETERS
// [cfe] A getter can't have formal parameters.
    => null;
get f4
([arg])
// [error line 23, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.GETTER_WITH_PARAMETERS
// [cfe] A getter can't have formal parameters.
    => null;
get f5
({arg})
// [error line 29, column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.GETTER_WITH_PARAMETERS
// [cfe] A getter can't have formal parameters.
    => null;

main() {
  f1;
  f2;
  f3;
  f4;
  f5;
}
