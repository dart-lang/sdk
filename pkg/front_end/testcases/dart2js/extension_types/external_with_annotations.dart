// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is the same as `external.dart`, except all external members have a
// `@pragma` annotation.

@JS()
library static_interop;

import 'dart:js_interop';

@JS()
@staticInterop
class A {}

@JS()
extension type B._(A a) {
  @annotation
  external B(A a);

  @annotation
  external B.named(int i);

  @annotation
  external A field;

  @annotation
  external A method();

  @annotation
  external T genericMethod<T extends B>(T t);

  @annotation
  external B get getter;

  @annotation
  external void set setter(B b);

  @annotation
  external B get property;

  @annotation
  external void set property(B b);

  @annotation
  external static A staticField;

  @annotation
  external static A staticMethod();

  @annotation
  external static T staticGenericMethod<T extends B>(T t);

  @annotation
  external static B get staticGetter;

  @annotation
  external static void set staticSetter(B b);

  @annotation
  external static B get staticProperty;

  @annotation
  external static void set staticProperty(B b);

  @annotation
  external B methodWithOptionalArgument([B? b]);
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
  b2 = b1.methodWithOptionalArgument(b2);
  b1 = b2.methodWithOptionalArgument();
}

const annotation = pragma('a pragma');
