// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int returnString1() => 's';
//                     ^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
// [cfe] A value of type 'String' can't be returned from a function with return type 'int'.

// OK to return anything from a void function with a "=>" body.
void returnNull() => null;
void returnString2() => 's';

main() {
  returnString1();
  returnNull();
  returnString2();
}
