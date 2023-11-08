// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

extension type B._(A a) {
  external B(A a);

  external B.named(int i);

  external A field;

  external A method();

  external T genericMethod<T extends B>(T t);

  external B get getter;

  external void set setter(B b);

  external static A staticField;

  external static A staticMethod();

  external static T staticGenericMethod<T>(T t);

  external static B get staticGetter;

  external static void set staticSetter(B b);
}

void method(A a) {
  B b1 = new B(a);
  B b2 = new B.named(0);
  a = b1.field;
  b1.field = a;
  a = b1.method();
  var f1 = b1.method;
  b2 = b2.genericMethod(b2);
  var f2 = b2.genericMethod;
  int Function(int) f3 = b2.genericMethod;
  b1 = b2.getter;
  b1.setter = b2;
  a = B.staticField;
  B.staticField = a;
  a = B.staticMethod();
  var f4 = B.staticMethod;
  b2 = B.staticGenericMethod(b2);
  var f5 = B.staticGenericMethod;
  String Function(String) f6 = B.staticGenericMethod;
  b1 = B.staticGetter;
  B.staticSetter = b2;
}