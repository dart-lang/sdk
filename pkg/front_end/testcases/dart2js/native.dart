// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for positive and negative uses of named declarations. This file is
// also used in tests/compiler/dart2js/model/native_test.dart.

import 'dart:_js_helper';

var topLevelField;

get topLevelGetter => null;

set topLevelSetter(_) {}

topLevelFunction() {}

// NON_NATIVE_EXTERNAL
external get externalTopLevelGetter;

// NON_NATIVE_EXTERNAL
external set externalTopLevelSetter(_);

// NON_NATIVE_EXTERNAL
external externalTopLevelFunction();

get nativeTopLevelGetter native;

set nativeTopLevelSetter(_) native;

nativeTopLevelFunction() native;

class Class {
  Class.generative();
  factory Class.fact() => null as dynamic;

  // NON_NATIVE_EXTERNAL
  external Class.externalGenerative();

  // NON_NATIVE_EXTERNAL
  external factory Class.externalFact();

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS
  Class.nativeGenerative() native;

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS
  factory Class.nativeFact() native;

  var instanceField;
  get instanceGetter => null;
  set instanceSetter(_) {}
  instanceMethod() {}

  static var staticField;
  static get staticGetter => null;
  static set staticSetter(_) {}
  static staticMethod() {}

  // NON_NATIVE_EXTERNAL
  external get externalInstanceGetter;

  // NON_NATIVE_EXTERNAL
  external set externalInstanceSetter(_);

  // NON_NATIVE_EXTERNAL
  external externalInstanceMethod();

  // NON_NATIVE_EXTERNAL
  external static get externalStaticGetter;

  // NON_NATIVE_EXTERNAL
  external static set externalStaticSetter(_);

  // NON_NATIVE_EXTERNAL
  external static externalStaticMethod();

  get nativeInstanceGetter native;
  set nativeInstanceSetter(_) native;
  nativeInstanceMethod() native;

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS
  static get nativeStaticGetter native;

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS
  static set nativeStaticSetter(_) native;

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS
  static nativeStaticMethod() native;
}

@Native('d')
class NativeClass {
  NativeClass.generative();

  factory NativeClass.fact() => null as dynamic;

  // NON_NATIVE_EXTERNAL
  external NativeClass.externalGenerative();
  // NON_NATIVE_EXTERNAL
  external factory NativeClass.externalFact();

  NativeClass.nativeGenerative() native;
  factory NativeClass.nativeFact() native;

  var instanceField;
  get instanceGetter => null;
  set instanceSetter(_) {}
  instanceMethod() {}

  static var staticField;
  static get staticGetter => null;
  static set staticSetter(_) {}
  static staticMethod() {}

  var instanceNamedField;

  // NON_NATIVE_EXTERNAL
  external get externalInstanceGetter;

  // NON_NATIVE_EXTERNAL
  external set externalInstanceSetter(_);

  // NON_NATIVE_EXTERNAL
  external externalInstanceMethod();

  // NON_NATIVE_EXTERNAL
  external static get externalStaticGetter;

  // NON_NATIVE_EXTERNAL
  external static set externalStaticSetter(_);

  // NON_NATIVE_EXTERNAL
  external static externalStaticMethod();

  get nativeInstanceGetter native;
  set nativeInstanceSetter(_) native;
  nativeInstanceMethod() native;

  static get nativeStaticGetter native;
  static set nativeStaticSetter(_) native;
  static nativeStaticMethod() native;
}

main() {
  if (true) return;

  topLevelField;
  topLevelGetter;
  topLevelSetter = null;
  topLevelFunction();
  externalTopLevelGetter;
  externalTopLevelSetter = null;
  externalTopLevelFunction();
  nativeTopLevelGetter;
  nativeTopLevelSetter = null;
  nativeTopLevelFunction();

  var c1 = new Class.generative();
  new Class.fact();
  new Class.externalGenerative();
  new Class.externalFact();
  new Class.nativeGenerative();
  new Class.nativeFact();
  c1.instanceField;
  c1.instanceGetter;
  c1.instanceSetter = null;
  c1.instanceMethod();
  Class.staticField;
  Class.staticGetter;
  Class.staticSetter = null;
  Class.staticMethod();
  c1.externalInstanceGetter;
  c1.externalInstanceSetter = null;
  c1.externalInstanceMethod();
  Class.externalStaticGetter;
  Class.externalStaticSetter = null;
  Class.externalStaticMethod();
  c1.nativeInstanceGetter;
  c1.nativeInstanceSetter = null;
  c1.nativeInstanceMethod();
  Class.nativeStaticGetter;
  Class.nativeStaticSetter = null;
  Class.nativeStaticMethod();

  var c2 = new NativeClass.generative();
  new NativeClass.fact();
  new NativeClass.externalGenerative();
  new NativeClass.externalFact();
  new NativeClass.nativeGenerative();
  new NativeClass.nativeFact();
  c2.instanceField;
  c2.instanceGetter;
  c2.instanceSetter = null;
  c2.instanceMethod();
  NativeClass.staticField;
  NativeClass.staticGetter;
  NativeClass.staticSetter = null;
  NativeClass.staticMethod();
  c2.externalInstanceGetter;
  c2.externalInstanceSetter = null;
  c2.externalInstanceMethod();
  NativeClass.externalStaticGetter;
  NativeClass.externalStaticSetter = null;
  NativeClass.externalStaticMethod();
  c2.nativeInstanceGetter;
  c2.nativeInstanceSetter = null;
  c2.nativeInstanceMethod();
  NativeClass.nativeStaticGetter;
  NativeClass.nativeStaticSetter = null;
  NativeClass.nativeStaticMethod();
}
