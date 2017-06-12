// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_fields_test;

/// Simple program creating an object and accessing its initialized fields.
void main() {
  var a = new A();
  print(a.f1);
  print(a.f2);

  new B(0);
  new B.redirecting1(0);
  new B.redirecting2(0);

  var c = new C.redirecting1(0);
  print(c.f1);
  print(c.f2);
}

class A {
  int f1 = 37;
  String f2 = 'hello world';
}

class B {
  B(int i);
  B.redirecting1(int i) : this(redirecting(i, 'B.redirecting1'));
  B.redirecting2(int i) : this.redirecting1(redirecting(i, 'B.redirecting2'));
}

class C {
  int f1 = fieldInitializer(0, 'C.f1');
  int f2 = fieldInitializer(1, 'C.f2');

  C(int i);
  C.redirecting1(int i) : this(redirecting(i, 'C.redirecting1'));
}

int redirecting(int i, String s) {
  print('$s: $i');
  return i + 1;
}

int fieldInitializer(int f, String s) {
  print('$s: $f');
  return f;
}
