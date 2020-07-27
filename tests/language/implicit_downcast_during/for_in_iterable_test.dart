// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

void main() {
  Object o = <A>[];
  for (var x in o) {}
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.
  for (B x in o) {}
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.
  B y;
  for (y in o) {}
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.
}
