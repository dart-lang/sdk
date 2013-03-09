// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

class MyClass {
  foo() => this..bar(3)..baz(4);
  bar(x) => x;
  baz(y) => y*2;
}

main() {
  var o = new MyClass();
  Expect.equals(o.foo(), o);
}
