// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_super_test;

/// Simple program creating an object with super constructor invocation.
void main() {
  print("Create A instance");
  var a = new A.withArgs(0);
  print(a.foo);

  print("Create B instance");
  var b1 = new B.withSuper();
  print(b1.foo);
  print(b1.bar);
}

class A {
  String foo;

  A.withArgs(int i) : foo = fieldInitializer(i, 'A.foo');
}

class B extends A {
  String bar;

  B.withSuper()
      : bar = fieldInitializer(0, 'B.bar'),
        super.withArgs(1);
}

String fieldInitializer(int f, String s) {
  print('$s: $f');
  return '$s: $f';
}
