// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_field_initializers_test;

/// Simple program creating an object with instance field initializers and
/// static fields in the declaration of the class.
void main() {
  print('Create instance of A');
  var a1 = new A();
  print(a1.foo1);
  print(a1.foo2);
  print(a1.foo3);

  print('Read staticFoo');
  print(A.staticFoo);
}

class A {
  static String staticFoo = 'staticFoo';
  String foo1 = 'foo1';
  String foo2;
  String foo3 = 'foo3';

  A() {
    this.foo2 = 'foo2';
  }
}
