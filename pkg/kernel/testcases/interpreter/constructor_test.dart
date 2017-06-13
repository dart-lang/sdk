// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constructor_test;

void main() {
  var a = new A();
  print(a.foo);
  print('******************');

  var b = new B();
  print(b.foo);
  print(b.bar);
}

class A {
  String foo = fieldInitializer(0, 'A.foo');

  A() : foo = fieldInitializer(1, 'A.foo') {
    foo = fieldInitializer(2, 'A.foo');
  }
}

class B extends A {
  String bar = fieldInitializer(0, 'B.bar');

  B() : bar = fieldInitializer(1, 'B.bar') {
    bar = fieldInitializer(2, 'B.bar');
  }
}

String fieldInitializer(int f, String s) {
  print('$s: $f');
  return '$s: $f';
}
