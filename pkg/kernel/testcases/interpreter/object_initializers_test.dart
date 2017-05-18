// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_initializers_test;

/// Simple program creating an object with field initializers.
void main() {
  var a = new A('foo1', 'foo2');
  print(a.foo1);
  print(a.foo2);

  var b = new B(fieldInitializer(0, 'foo1'), fieldInitializer(0, 'foo2'));
  print(b.foo1);
  print(b.foo2);
  print(b.foo3);
}

class A {
  String foo1;
  String foo2;

  A(String foo1, String foo2)
      : foo1 = foo1,
        foo2 = foo2;
}

class B {
  String foo1 = fieldInitializer(1, 'foo1');
  String foo2 = fieldInitializer(1, 'foo2');
  String foo3 = fieldInitializer(1, 'foo3');

  B(this.foo1, this.foo2) : foo3 = foo2;
}

String fieldInitializer(int f, String s) {
  print('$s: $f');
  return '$s: $f';
}
