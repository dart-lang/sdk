// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that a setter has a single argument.

set tooFew() {}
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//        ^
// [cfe] A setter should have exactly one formal parameter.

set tooMany(var value, var extra) {}
//  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//         ^
// [cfe] A setter should have exactly one formal parameter.

main() {
  tooFew = 1;
  tooMany = 2;
}
