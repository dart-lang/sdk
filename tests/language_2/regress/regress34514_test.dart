// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Inferred type should be `int`
var x = (() => 1)();

main() {
  x = 'bad'; // `String` not assignable to `int`
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}
