// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

void main() {
  testIllegalArgument();
}

void testIllegalArgument() {
  String a = "Hello";
  var c = a[2.2];
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.
}
