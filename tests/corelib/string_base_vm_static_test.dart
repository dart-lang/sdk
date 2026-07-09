// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing class 'StringBase' (currently VM specific).

import "package:expect/expect.dart";

void main() {
  String s4 = new String.fromCharCodes([0.0]);
  //                                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.
}
