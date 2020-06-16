// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test for positive and negative uses of named declarations. This file is
// also used in tests/compiler/dart2js/model/native_test.dart.

import 'dart:_js_helper';

var topLevelField;

get topLevelGetter => null;

set topLevelSetter(_) {}

topLevelFunction() {}

// NON_NATIVE_EXTERNAL               //# 01: compile-time error
external get externalTopLevelGetter; //# 01: continued

// NON_NATIVE_EXTERNAL                  //# 02: compile-time error
external set externalTopLevelSetter(_); //# 02: continued

// NON_NATIVE_EXTERNAL               //# 03: compile-time error
external externalTopLevelFunction(); //# 03: continued

get nativeTopLevelGetter native;

set nativeTopLevelSetter(_) native;

nativeTopLevelFunction() native;

class Class {
  Class.generative();
  factory Class.fact() => null;

  // NON_NATIVE_EXTERNAL               //# 08: compile-time error
  external Class.externalGenerative(); //# 08: continued

  // NON_NATIVE_EXTERNAL                 //# 09: compile-time error
  external factory Class.externalFact(); //# 09: continued

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS //# 10: compile-time error
  Class.nativeGenerative() native; //# 10: continued

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS //# 11: compile-time error
  factory Class.nativeFact() native; //# 11: continued

  var instanceField;
  get instanceGetter => null;
  set instanceSetter(_) {}
  instanceMethod() {}

  static var staticField;
  static get staticGetter => null;
  static set staticSetter(_) {}
  static staticMethod() {}

  // NON_NATIVE_EXTERNAL               //# 22: compile-time error
  external get externalInstanceGetter; //# 22: continued

  // NON_NATIVE_EXTERNAL                  //# 23: compile-time error
  external set externalInstanceSetter(_); //# 23: continued

  // NON_NATIVE_EXTERNAL             //# 24: compile-time error
  external externalInstanceMethod(); //# 24: continued

  // NON_NATIVE_EXTERNAL                    //# 25: compile-time error
  external static get externalStaticGetter; //# 25: continued

  // NON_NATIVE_EXTERNAL                       //# 26: compile-time error
  external static set externalStaticSetter(_); //# 26: continued

  // NON_NATIVE_EXTERNAL                  //# 27: compile-time error
  external static externalStaticMethod(); //# 27: continued

  get nativeInstanceGetter native;
  set nativeInstanceSetter(_) native;
  nativeInstanceMethod() native;

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS //# 28: compile-time error
  static get nativeStaticGetter native; //# 28: continued

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS //# 29: compile-time error
  static set nativeStaticSetter(_) native; //# 29: continued

  // NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS //# 30: compile-time error
  static nativeStaticMethod() native; //# 30: continued
}

@Native('d')
class NativeClass {
  NativeClass.generative();

  factory NativeClass.fact() => null;

  // NON_NATIVE_EXTERNAL                     //# 31: compile-time error
  external NativeClass.externalGenerative(); //# 31: continued
  // NON_NATIVE_EXTERNAL                       //# 32: compile-time error
  external factory NativeClass.externalFact(); //# 32: continued

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

  // NON_NATIVE_EXTERNAL               //# 36: compile-time error
  external get externalInstanceGetter; //# 36: continued

  // NON_NATIVE_EXTERNAL                  //# 37: compile-time error
  external set externalInstanceSetter(_); //# 37: continued

  // NON_NATIVE_EXTERNAL             //# 38: compile-time error
  external externalInstanceMethod(); //# 38: continued

  // NON_NATIVE_EXTERNAL                    //# 39: compile-time error
  external static get externalStaticGetter; //# 39: continued

  // NON_NATIVE_EXTERNAL                       //# 40: compile-time error
  external static set externalStaticSetter(_); //# 40: continued

  // NON_NATIVE_EXTERNAL                  //# 41: compile-time error
  external static externalStaticMethod(); //# 41: continued

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
  externalTopLevelGetter; //# 01: continued
  externalTopLevelSetter = null; //# 02: continued
  externalTopLevelFunction(); //# 03: continued
  nativeTopLevelGetter;
  nativeTopLevelSetter = null;
  nativeTopLevelFunction();

  var c1 = new Class.generative();
  new Class.fact();
  new Class.externalGenerative(); //# 08: continued
  new Class.externalFact(); //# 09: continued
  new Class.nativeGenerative(); //# 10: continued
  new Class.nativeFact(); //# 11: continued
  c1.instanceField;
  c1.instanceGetter;
  c1.instanceSetter = null;
  c1.instanceMethod();
  Class.staticField;
  Class.staticGetter;
  Class.staticSetter = null;
  Class.staticMethod();
  c1.externalInstanceGetter; //# 22: continued
  c1.externalInstanceSetter = null; //# 23: continued
  c1.externalInstanceMethod(); //# 24: continued
  Class.externalStaticGetter; //# 25: continued
  Class.externalStaticSetter = null; //# 26: continued
  Class.externalStaticMethod(); //# 27: continued
  c1.nativeInstanceGetter;
  c1.nativeInstanceSetter = null;
  c1.nativeInstanceMethod();
  Class.nativeStaticGetter; //# 28: continued
  Class.nativeStaticSetter = null; //# 29: continued
  Class.nativeStaticMethod(); //# 30: continued

  var c2 = new NativeClass.generative();
  new NativeClass.fact();
  new NativeClass.externalGenerative(); //# 31: continued
  new NativeClass.externalFact(); //# 32: continued
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
  c2.externalInstanceGetter; //# 36: continued
  c2.externalInstanceSetter = null; //# 37: continued
  c2.externalInstanceMethod(); //# 38: continued
  NativeClass.externalStaticGetter; //# 39: continued
  NativeClass.externalStaticSetter = null; //# 40: continued
  NativeClass.externalStaticMethod(); //# 41: continued
  c2.nativeInstanceGetter;
  c2.nativeInstanceSetter = null;
  c2.nativeInstanceMethod();
  NativeClass.nativeStaticGetter;
  NativeClass.nativeStaticSetter = null;
  NativeClass.nativeStaticMethod();
}
