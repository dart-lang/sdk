// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fieldtest;

class A {
  int x = 42;
}

int foo(A a) {
  print(a.x);
  return a.x;
}

int bar(a) {
  print(a.x);
  return a.x;
}

baz(A a) => a.x;

void main() {
  var a = new A();
  foo(a);
  bar(a);
  print(baz(a));
}
