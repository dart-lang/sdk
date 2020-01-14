// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test for dart2js to handle a typed selector with a typedef as a
// receiver type.

getComparator() => (a, b) => 42;

class A {
  foo() => 42;
}

main() {
  Comparator a = getComparator();
  if (a(1, 2) != 42) {
    // This call used to crash dart2js because 'foo' was a typed
    // selector with a typedef as a receiver type.
    a.foo(); /*@compile-error=unspecified*/
  }
  var b = new A();
  b.foo();
}
