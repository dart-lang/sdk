// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

class A {
  operator ==(other) => 1;
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
  operator <(other) => null;
  operator <=(other) => 499;
  operator >(other) => "foo";
  operator >=(other) => 42;
}

// This triggered a bug in Dart2Js: equality operator was always boolified.
equals(a) {
  Expect.equals(1, a == a);
}

less(a) {
  Expect.equals(null, a < a);
}

lessEqual(a) {
  Expect.equals(499, a <= a);
}

greater(a) {
  Expect.equals("foo", a > a);
}

greaterEqual(a) {
  Expect.equals(42, a >= a);
}

main() {
  var a = new A();
  equals(a);
  less(a);
  lessEqual(a);
  greater(a);
  greaterEqual(a);
}
