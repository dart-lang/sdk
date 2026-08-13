// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library static_interop;

import 'dart:js_interop';

@JS()
extension type B._(JSObject a) implements JSObject {
  // Constructors.
  external B(JSObject a);

  external B.named(int i);

  external factory B.factory(JSObject a);

  external factory B.namedParams({JSObject a});

  // Non-static fields.
  external JSObject field;

  external final JSObject finalField;

  @JS('renamedF')
  external JSObject renamedField;

  @JS('renamedF1.F2')
  external JSObject renamedField2;

  @JS('renamedF1.F2.F3')
  external JSObject renamedField3;

  // Non-static methods.
  external JSObject method();

  @JS('renamedM')
  external JSObject renamedMethod();

  @JS('renamedM1.M2')
  external JSObject renamedMethod2();

  @JS('renamedM1.M2.M3')
  external JSObject renamedMethod3();

  external T genericMethod<T extends B>(T t);

  external B methodWithOptionalArgument([B? b]);

  // Non-static getters and setters.
  external B get getter;

  external void set setter(B b);

  external B get property;

  external void set property(B b);

  @JS('renamedG')
  external B get renamedGetter;

  @JS('renamedG1.G2')
  external B get renamedGetter2;

  @JS('renamedG1.G2.G3')
  external B get renamedGetter3;

  @JS('renamedS')
  external void set renamedSetter(B b);

  @JS('renamedS1.S2')
  external void set renamedSetter2(B b);

  @JS('renamedS1.S2.S3')
  external void set renamedSetter3(B b);

  // Static fields.
  external static JSObject staticField;

  @JS('renamedSF')
  external static JSObject renamedStaticField;

  @JS('renamedSF1.SF2')
  external static JSObject renamedStaticField2;

  @JS('renamedSF1.SF2.SF3')
  external static JSObject renamedStaticField3;

  // Static methods.
  external static JSObject staticMethod();

  @JS('renamedSM')
  external static JSObject renamedStaticMethod();

  @JS('renamedSM1.SM2')
  external static JSObject renamedStaticMethod2();

  @JS('renamedSM1.SM2.SM3')
  external static JSObject renamedStaticMethod3();

  external static T staticGenericMethod<T extends B>(T t);

  // Static getters and setters.
  external static B get staticGetter;

  external static void set staticSetter(B b);

  external static B get staticProperty;

  external static void set staticProperty(B b);

  @JS('renamedSG')
  external static B get renamedStaticGetter;

  @JS('renamedSG1.SG2')
  external static B get renamedStaticGetter2;

  @JS('renamedSG1.SG2.SG3')
  external static B get renamedStaticGetter3;

  @JS('renamedSS')
  external static void set renamedStaticSetter(B b);

  @JS('renamedSS1.SS2')
  external static void set renamedStaticSetter2(B b);

  @JS('renamedSS1.SS2.SS3')
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
