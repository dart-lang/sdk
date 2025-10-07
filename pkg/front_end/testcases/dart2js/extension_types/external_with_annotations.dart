// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is the same as `external.dart`, except all external members have a
// `@pragma` annotation.

@JS()
library static_interop;

import 'dart:js_interop';

@JS()
extension type B._(JSObject a) implements JSObject {
  // Constructors.
  @annotation
  external B(JSObject a);

  @annotation
  external B.named(int i);

  @annotation
  external factory B.factory(JSObject a);

  @annotation
  external factory B.namedParams({JSObject a});

  // Non-static fields.
  @annotation
  external JSObject field;

  @annotation
  external final JSObject finalField;

  @JS('renamedF')
  @annotation
  external JSObject renamedField;

  @JS('renamedF1.F2')
  @annotation
  external JSObject renamedField2;

  @JS('renamedF1.F2.F3')
  @annotation
  external JSObject renamedField3;

  // Non-static methods.
  @annotation
  external JSObject method();

  @JS('renamedM')
  @annotation
  external JSObject renamedMethod();

  @JS('renamedM1.M2')
  @annotation
  external JSObject renamedMethod2();

  @JS('renamedM1.M2.M3')
  @annotation
  external JSObject renamedMethod3();

  @annotation
  external T genericMethod<T extends B>(T t);

  @annotation
  external B methodWithOptionalArgument([B? b]);

  // Non-static getters and setters.
  @annotation
  external B get getter;

  @annotation
  external void set setter(B b);

  @annotation
  external B get property;

  @annotation
  external void set property(B b);

  @JS('renamedG')
  @annotation
  external B get renamedGetter;

  @JS('renamedG1.G2')
  @annotation
  external B get renamedGetter2;

  @JS('renamedG1.G2.G3')
  @annotation
  external B get renamedGetter3;

  @JS('renamedS')
  @annotation
  external void set renamedSetter(B b);

  @JS('renamedS1.S2')
  @annotation
  external void set renamedSetter2(B b);

  @JS('renamedS1.S2.S3')
  @annotation
  external void set renamedSetter3(B b);

  // Static fields.
  @annotation
  external static JSObject staticField;

  @JS('renamedSF')
  @annotation
  external static JSObject renamedStaticField;

  @JS('renamedSF1.SF2')
  @annotation
  external static JSObject renamedStaticField2;

  @JS('renamedSF1.SF2.SF3')
  @annotation
  external static JSObject renamedStaticField3;

  // Static methods.
  @annotation
  external static JSObject staticMethod();

  @JS('renamedSM')
  @annotation
  external static JSObject renamedStaticMethod();

  @JS('renamedSM1.SM2')
  @annotation
  external static JSObject renamedStaticMethod2();

  @JS('renamedSM1.SM2.SM3')
  @annotation
  external static JSObject renamedStaticMethod3();

  @annotation
  external static T staticGenericMethod<T extends B>(T t);

  // Static getters and setters.
  @annotation
  external static B get staticGetter;

  @annotation
  external static void set staticSetter(B b);

  @annotation
  external static B get staticProperty;

  @annotation
  external static void set staticProperty(B b);

  @JS('renamedSG')
  @annotation
  external static B get renamedStaticGetter;

  @JS('renamedSG1.SG2')
  @annotation
  external static B get renamedStaticGetter2;

  @JS('renamedSG1.SG2.SG3')
  @annotation
  external static B get renamedStaticGetter3;

  @JS('renamedSS')
  @annotation
  external static void set renamedStaticSetter(B b);

  @JS('renamedSS1.SS2')
  @annotation
  external static void set renamedStaticSetter2(B b);

  @JS('renamedSS1.SS2.SS3')
  @annotation
  external static void set renamedStaticSetter3(B b);
}

void method(JSObject a) {
  B b1 = new B(a);
  B b2 = new B.named(0);
  B b3 = B.factory(b2);
  B b4 = B.namedParams(a: a);

  a = b1.field;
  b1.field = a;
  a = b1.finalField;
  a = b1.renamedField;
  a = b1.renamedField2;
  a = b1.renamedField3;
  b1.renamedField = a;
  b1.renamedField2 = a;
  b1.renamedField3 = a;

  a = b1.method();
  a = b1.renamedMethod();
  a = b1.renamedMethod2();
  a = b1.renamedMethod3();
  b2 = b2.genericMethod(b2);
  b2 = b1.methodWithOptionalArgument(b2);
  b1 = b2.methodWithOptionalArgument();

  b1 = b2.getter;
  b1.setter = b2;
  b1.property = b2.property;
  b1 = b2.renamedGetter;
  b1 = b2.renamedGetter2;
  b1 = b2.renamedGetter3;
  b1.renamedSetter = b2;
  b1.renamedSetter2 = b2;
  b1.renamedSetter3 = b2;

  a = B.staticField;
  B.staticField = a;
  a = B.renamedStaticField;
  a = B.renamedStaticField2;
  a = B.renamedStaticField3;
  B.renamedStaticField = a;
  B.renamedStaticField2 = a;
  B.renamedStaticField3 = a;

  a = B.staticMethod();
  B.renamedStaticMethod();
  B.renamedStaticMethod2();
  B.renamedStaticMethod3();
  b2 = B.staticGenericMethod(b2);

  b1 = B.staticGetter;
  B.staticSetter = b2;
  B.staticProperty = B.staticProperty;
  b1 = B.renamedStaticGetter;
  b1 = B.renamedStaticGetter2;
  b1 = B.renamedStaticGetter3;
  B.renamedStaticSetter = b2;
  B.renamedStaticSetter2 = b2;
  B.renamedStaticSetter3 = b2;
}

const annotation = pragma('a pragma');
