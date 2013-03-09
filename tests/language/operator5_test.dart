// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  operator ==(other) => 1;
  operator <(other) => null;
  operator <=(other) => 499;
  operator >(other) => "foo";
  operator >=(other) => 42;
}

// This triggered a bug in Dart2Js: equality operator was always boolified.
equals(a) {
  try {
    Expect.equals(1, a == a);
  } on TypeError catch (e) {
    // In checked mode the test doesn't do anything.
  }
}

less(a) {
  try {
    Expect.equals(null, a < a);
  } on TypeError catch (e) {}
}

lessEqual(a) {
  try {
    Expect.equals(499, a <= a);
  } on TypeError catch (e) {}
}

greater(a) {
  try {
    Expect.equals("foo", a > a);
  } on TypeError catch (e) {}
}

greaterEqual(a) {
  try {
    Expect.equals(42, a >= a);
  } on TypeError catch (e) {}
}

main() {
  var a = new A();
  equals(a);
  less(a);
  lessEqual(a);
  greater(a);
  greaterEqual(a);
}
