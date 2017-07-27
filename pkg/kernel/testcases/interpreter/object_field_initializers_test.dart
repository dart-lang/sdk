// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_field_initializers_test;

/// Simple program creating an object with instance field initializers in the
/// declaration of the class.
///
/// The static function `fieldInitializer` is used to ensure the fields are
/// intialized in the correct order by tracking the  order of side effects.
void main() {
  var a1 = new A.withoutArguments();
  print(a1.foo1);
  print(a1.foo2);
  print(a1.foo3);
  var a2 = new A('bar1', 'bar2');
  print(a2.foo1);
  print(a2.foo2);
  print(a2.foo3);

  var b = new B(fieldInitializer(1, 'bar1'), fieldInitializer(2, 'bar2'));
  print(b.foo1);
  print(b.foo2);
  print(b.foo3);
  print(b.foo4);
}

class A {
  String foo1 = 'foo1';
  String foo2;
  String foo3 = 'foo3';

  A.withoutArguments();
  A(String foo1, String foo2) {
    this.foo1 = foo1;
    this.foo2 = foo2;
  }
}

class B {
  String foo1 = fieldInitializer(3, 'foo1');
  String foo2;
  String foo3 = fieldInitializer(4, 'foo3');
  String foo4 = fieldInitializer(5, 'foo4');

  B(String foo1, String foo2) {
    this.foo1 = foo1;
    this.foo2 = foo2;
    this.foo4 = fieldInitializer(6, 'bar4');
  }
}

String fieldInitializer(int f, String s) {
  print('$s: $f');
  return '$s: $f';
}
