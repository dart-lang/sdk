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
  } catch(TypeError e) {
    // In checked mode the test doesn't do anything.
  }
}

equalsNull(a) {
  try {
    Expect.equals(1, a == null);
  } catch(TypeError e) {
    // In checked mode the test doesn't do anything.
  }
}

less(a) {
  try {
    Expect.equals(null, a < a);
  } catch(TypeError e) {}
}

lessEqual(a) {
  try {
    Expect.equals(499, a <= a);
  } catch(TypeError e) {}
}

greater(a) {
  try {
    Expect.equals("foo", a > a);
  } catch(TypeError e) {}
}

greaterEqual(a) {
  try {
    Expect.equals(42, a >= a);
  } catch(TypeError e) {}
}

main() {
  var a = new A();
  equals(a);
  less(a);
  lessEqual(a);
  greater(a);
  greaterEqual(a);
}
