// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  operator ==(other) => 1; /*@compile-error=unspecified*/
  operator <(other) => null; /*@compile-error=unspecified*/
  operator <=(other) => 499; /*@compile-error=unspecified*/
  operator >(other) => "foo"; /*@compile-error=unspecified*/
  operator >=(other) => 42; /*@compile-error=unspecified*/
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
