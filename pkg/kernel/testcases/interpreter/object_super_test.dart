// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_super_test;

/// Simple program creating an object with super constructor invocation.
void main() {
  var a = new A.withArgs(0);
  print(a.foo);

  var b1 = new B.withSuper();
  print(b1.foo);
  print(b1.bar);

  var b2 = new B();
  print(b2.foo);
  print(b2.bar);
}

class A {
  String foo;

  A() : this.withArgs(0);
  A.withArgs(int i) : foo = fieldInitializer(i, 'A.foo');
}

class B extends A {
  String bar;

  B();
  B.withSuper()
      : bar = fieldInitializer(0, 'B.bar'),
        super.withArgs(1);
}

String fieldInitializer(int f, String s) {
  print('$s: $f');
  return '$s: $f';
}
