// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test an invalid double format

main() {
  3457e
//^
// [cfe] Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).
//    ^
// [analyzer] SYNTACTIC_ERROR.MISSING_DIGIT
  ;
}
