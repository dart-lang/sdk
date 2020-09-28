// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

void main() {
  A a = new B();
  <B, Object>{a: 1};
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
  <Object, B>{1: a};
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
}
