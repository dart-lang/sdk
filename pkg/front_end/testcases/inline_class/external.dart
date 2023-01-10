// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

inline class B {
  final A a;

  external B(A a);

  external B.named(int i);

  external A method();

  external T genericMethod<T>(T t);

  external B get getter;

  external void set setter(B b);

  // TODO(johnniwinther): Support static fields.
  //static external A staticField;

  static external A staticMethod();

  static external T staticGenericMethod<T>(T t);

  static external B get staticGetter;

  static external void set staticGetter(B b);
}

void method(A a) {
  B b1 = new B(a);
  B b2 = new B.named(0);
  a = b1.method();
  b2 = b2.genericMethod(b2);
  b1 = b2.getter;
  b1.setter = b2;
  //a = B.staticField;
  //B.staticField = a;
  a = B.staticMethod;
  b2 = B.staticGenericMethod(b2);
  b1 = B.staticGetter;
  B.staticSetter = b2;
}