// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Share this test with ddc.

// Test for positive and negative uses of js-interop declarations in a library
// _with_ a @JS() annotation. This file is also used in
// tests/compiler/dart2js/model/native_test.dart.

@JS()
library lib;

import 'package:js/js.dart';

var topLevelField;

get topLevelGetter => null;

set topLevelSetter(_) {}

topLevelFunction() {}

@JS('a') // JS_INTEROP_FIELD_NOT_SUPPORTED  //# 01: compile-time error
var topLevelJsInteropField; //# 01: continued

@JS('a') // JS_INTEROP_NON_EXTERNAL_MEMBER  //# 02: compile-time error
get topLevelJsInteropGetter => null; //# 02: continued

@JS('a') // JS_INTEROP_NON_EXTERNAL_MEMBER  //# 03: compile-time error
set topLevelJsInteropSetter(_) {} //# 03: continued

@JS('a') // JS_INTEROP_NON_EXTERNAL_MEMBER  //# 04: compile-time error
topLevelJsInteropFunction() {} //# 04: continued

external get externalTopLevelGetter;

external set externalTopLevelSetter(_);

external externalTopLevelFunction();

@JS('a')
external get externalTopLevelJsInteropGetter;

@JS('b')
external set externalTopLevelJsInteropSetter(_);

@JS('c')
external externalTopLevelJsInteropFunction();

class Class {
  Class.generative();
  factory Class.fact() => null as dynamic;

  // NON_NATIVE_EXTERNAL               //# 08: compile-time error
  external Class.externalGenerative(); //# 08: continued

  // NON_NATIVE_EXTERNAL                 //# 09: compile-time error
  external factory Class.externalFact(); //# 09: continued

  @JS('a') // GENERIC  //# 10: compile-time error
  Class.jsInteropGenerative(); //# 10: continued

  @JS('a') // GENERIC  //# 11: compile-time error
  factory Class.jsInteropFact() => null; //# 11: continued

  @JS('a') // GENERIC  //# 12: compile-time error
  external Class.externalJsInteropGenerative(); //# 12: continued

  @JS('a') // GENERIC  //# 13: compile-time error
  external factory Class.externalJsInteropFact(); //# 13: continued

  var instanceField;
  get instanceGetter => null;
  set instanceSetter(_) {}
  instanceMethod() {}

  static var staticField;
  static get staticGetter => null;
  static set staticSetter(_) {}
  static staticMethod() {}

  @JS('a') // GENERIC  //# 14: compile-time error
  var instanceJsInteropField; //# 14: continued

  @JS('a') // GENERIC  //# 15: compile-time error
  get instanceJsInteropGetter => null; //# 15: continued

  @JS('a') // GENERIC  //# 16: compile-time error
  set instanceJsInteropSetter(_) {} //# 16: continued

  @JS('a') // GENERIC  //# 17: compile-time error
  instanceJsInteropMethod() {} //# 17: continued

  @JS('a') // GENERIC  //# 18: compile-time error
  static var staticJsInteropField; //# 18: continued

  @JS('a') // GENERIC //# 19: compile-time error
  static get staticJsInteropGetter => null; //# 19: continued

  @JS('a') // GENERIC  //# 20: compile-time error
  static set staticJsInteropSetter(_) {} //# 20: continued

  @JS('a') // GENERIC  //# 21: compile-time error
  static staticJsInteropMethod() {} //# 21: continued

  // NON_NATIVE_EXTERNAL               //# 22: compile-time error
  external get externalInstanceGetter; //# 22: continued

  // NON_NATIVE_EXTERNAL                  //# 23: compile-time error
  external set externalInstanceSetter(_); //# 23: continued

  // NON_NATIVE_EXTERNAL             //# 24: compile-time error
  external externalInstanceMethod(); //# 24: continued

  // NON_NATIVE_EXTERNAL             //# 25: compile-time error
  external static get externalStaticGetter; //# 25: continued

  // NON_NATIVE_EXTERNAL                //# 26: compile-time error
  external static set externalStaticSetter(_); //# 26: continued

  // NON_NATIVE_EXTERNAL           //# 27: compile-time error
  external static externalStaticMethod(); //# 27: continued

  @JS('a') // GENERIC  //# 28: compile-time error
  external get externalInstanceJsInteropGetter; //# 28: continued

  @JS('a') // GENERIC  //# 29: compile-time error
  external set externalInstanceJsInteropSetter(_); //# 29: continued

  @JS('a') // GENERIC  //# 30: compile-time error
  external externalInstanceJsInteropMethod(); //# 30: continued

  @JS('a') // GENERIC  //# 31: compile-time error
  external static get externalStaticJsInteropGetter; //# 31: continued

  @JS('a') // GENERIC  //# 32: compile-time error
  external static set externalStaticJsInteropSetter(_); //# 32: continued

  @JS('a') // GENERIC  //# 33: compile-time error
  external static externalStaticJsInteropMethod(); //# 33: continued
}

@JS('d')
class JsInteropClass {
  // GENERIC //# 34: compile-time error
  JsInteropClass.generative(); //# 34: continued

  // JS_INTEROP_CLASS_NON_EXTERNAL_CONSTRUCTOR //# 35: compile-time error
  factory JsInteropClass.fact() => null; //# 35: continued

  external JsInteropClass.externalGenerative();
  external factory JsInteropClass.externalFact();

  @JS('a') // GENERIC //# 36: compile-time error
  JsInteropClass.jsInteropGenerative(); //# 36: continued

  @JS('a') // JS_INTEROP_CLASS_NON_EXTERNAL_CONSTRUCTOR //# 37: compile-time error
  factory JsInteropClass.jsInteropFact() => null; //# 37: continued

  @JS('a')
  external JsInteropClass.externalJsInteropGenerative();

  @JS('a')
  external factory JsInteropClass.externalJsInteropFact();

  // IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED //# 38: compile-time error
  var instanceField; //# 38: continued

  // GENERIC //# 39: compile-time error
  get instanceGetter => null; //# 39: continued

  // GENERIC //# 40: compile-time error
  set instanceSetter(_) {} //# 40: continued

  // GENERIC //# 41: compile-time error
  instanceMethod() {} //# 41: continued

  // IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED //# 42: compile-time error
  static var staticField; //# 42: continued

  // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 43: compile-time error
  static get staticGetter => null; //# 43: continued

  // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 44: compile-time error
  static set staticSetter(_) {} //# 44: continued

  // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 45: compile-time error
  static staticMethod() {} //# 45: continued

  @JS('a') // GENERIC //# 46: compile-time error
  var instanceJsInteropField; //# 46: continued

  @JS('a') // GENERIC //# 48: compile-time error
  get instanceJsInteropGetter => null; //# 48: continued

  @JS('a') // GENERIC //# 49: compile-time error
  set instanceJsInteropSetter(_) {} //# 49: continued

  @JS('a') // GENERIC //# 50: compile-time error
  instanceJsInteropMethod() {} //# 50: continued

  @JS('a') // IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED //# 51: compile-time error
  static var staticJsInteropField; //# 51: continued

  @JS('a') // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 52: compile-time error
  static get staticJsInteropGetter => null; //# 52: continued

  @JS('a') // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 53: compile-time error
  static set staticJsInteropSetter(_) {} //# 53: continued

  @JS('a') // JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER //# 54: compile-time error
  static staticJsInteropMethod() {} //# 54: continued

  external get externalInstanceGetter;
  external set externalInstanceSetter(_);
  external externalInstanceMethod();

  external static get externalStaticGetter;
  external static set externalStaticSetter(_);
  external static externalStaticMethod();

  @JS('a')
  external get externalInstanceJsInteropGetter;

  @JS('a')
  external set externalInstanceJsInteropSetter(_);

  @JS('a')
  external externalInstanceJsInteropMethod();

  @JS('a')
  external static get externalStaticJsInteropGetter;

  @JS('a')
  external static set externalStaticJsInteropSetter(_);

  @JS('a')
  external static externalStaticJsInteropMethod();
}

main() {
  if (false) {
    topLevelSetter = topLevelField = topLevelGetter;
    topLevelFunction();
    externalTopLevelSetter = externalTopLevelGetter;
    externalTopLevelFunction();
    externalTopLevelJsInteropSetter = externalTopLevelJsInteropGetter;
    externalTopLevelJsInteropFunction();
    Class c1 = new Class.generative();
    new Class.fact();
    c1.instanceSetter = c1.instanceField = c1.instanceGetter;
    c1.instanceMethod();
    Class.staticSetter = Class.staticField = Class.staticGetter;
    Class.staticMethod();
    JsInteropClass c2 = new JsInteropClass.externalGenerative();
    new JsInteropClass.externalFact();
    new JsInteropClass.externalJsInteropGenerative();
    new JsInteropClass.externalJsInteropFact();
    c2.externalInstanceSetter = c2.externalInstanceGetter;
    c2.externalInstanceMethod();
    c2.externalInstanceJsInteropSetter = c2.externalInstanceJsInteropGetter;
    c2.externalInstanceJsInteropMethod();
    JsInteropClass.externalStaticSetter = JsInteropClass.externalStaticGetter;
    JsInteropClass.externalStaticMethod();
    JsInteropClass.externalStaticJsInteropSetter =
        JsInteropClass.externalStaticJsInteropGetter;
    JsInteropClass.externalStaticJsInteropMethod();
  }
}
