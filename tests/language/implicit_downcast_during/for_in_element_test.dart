// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

void main() {
  List<A> listOfA = <A>[new B()];
  Object o = listOfA;
  for (B x in o) {}
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.
  for (B x in listOfA) {}
  //     ^
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
  //          ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_ELEMENT_TYPE
  B y;
  for (y in o) {}
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.
  for (y in listOfA) {}
  //     ^
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
  //        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_ELEMENT_TYPE
}
