// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library static_interop;

import 'dart:js_interop';

@JS()
@staticInterop
class A {}

@JS()
extension type B._(A a) {
  external B(A a);

  external B.named(int i);

  external A field;

  external A method();

  external T genericMethod<T extends B>(T t);

  external B get getter;

  external void set setter(B b);

  external B get property;

  external void set property(B b);

  external static A staticField;

  external static A staticMethod();

  external static T staticGenericMethod<T extends B>(T t);

  external static B get staticGetter;

  external static void set staticSetter(B b);

  external static B get staticProperty;

  external static void set staticProperty(B b);
}

void method(A a) {
  B b1 = new B(a);
  B b2 = new B.named(0);
  a = b1.field;
  b1.field = a;
  a = b1.method();
  b2 = b2.genericMethod(b2);
  b1 = b2.getter;
  b1.setter = b2;
  b1.property = b2.property;
  a = B.staticField;
  B.staticField = a;
  a = B.staticMethod();
  b2 = B.staticGenericMethod(b2);
  b1 = B.staticGetter;
  B.staticSetter = b2;
  B.staticProperty = B.staticProperty;
}