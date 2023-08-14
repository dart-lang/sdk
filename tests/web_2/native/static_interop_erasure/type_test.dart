// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the type and subtyping relationships between static interop,
// non-static interop, and Native classes are well-formed.

@JS()
library type_test;

import 'dart:_interceptors' show JavaScriptObject;

import 'package:expect/minitest.dart';
import 'package:js/js.dart';

import '../native_testing.dart' hide JS;
import '../native_testing.dart' as native_testing;

NativeClass makeNativeClass() native;

@Native('NativeClass')
class NativeClass extends JavaScriptObject {
  factory NativeClass() => makeNativeClass();
}

@JS('NativeClass')
@staticInterop
class StaticNativeClass {
  external factory StaticNativeClass();
}

@JS()
class JSClass {
  external JSClass();
}

@JS('JSClass')
@staticInterop
class StaticJSClass {
  external factory StaticJSClass();
}

@JS()
@anonymous
class AnonymousClass {
  external factory AnonymousClass();
}

@JS()
@staticInterop
class GenericStaticJSClass<T> {}

NativeClass returnNativeClass() => throw '';

StaticNativeClass returnStaticNativeClass() => throw '';

JSClass returnJSClass() => throw '';

StaticJSClass returnStaticJSClass() => throw '';

AnonymousClass returnAnonymousClass() => throw '';

GenericStaticJSClass<int> returnGenericStaticJSClassInt() => throw '';

void main() {
  nativeTesting();
  native_testing.JS('', r'''
    (function(){
      function NativeClass() {}
      self.NativeClass = NativeClass;
      self.makeNativeClass = function(){return new NativeClass()};
      self.nativeConstructor(NativeClass);
      function JSClass() {}
      self.JSClass = JSClass;
    })()
  ''');
  applyTestExtensions(['NativeClass']);

  var nativeClass = NativeClass();
  var staticNativeClass = StaticNativeClass();
  var jsClass = JSClass();
  var staticJsClass = StaticJSClass();
  var anonymousClass = AnonymousClass();

  // Native objects can be interop'd with static interop classes.
  expect(nativeClass is StaticNativeClass, true);
  expect(confuse(nativeClass) is StaticNativeClass, true);
  expect(() => nativeClass as StaticNativeClass, returnsNormally);

  expect(staticNativeClass is NativeClass, true);
  expect(confuse(staticNativeClass) is NativeClass, true);
  expect(() => staticNativeClass as NativeClass, returnsNormally);

  // Likewise, non-native JS objects can be interop'd with static interop
  // classes as well.
  expect(jsClass is StaticJSClass, true);
  expect(confuse(jsClass) is StaticJSClass, true);
  expect(() => jsClass as StaticJSClass, returnsNormally);

  expect(staticJsClass is JSClass, true);
  expect(confuse(staticJsClass) is JSClass, true);
  expect(() => staticJsClass as JSClass, returnsNormally);

  expect(anonymousClass is StaticJSClass, true);
  expect(confuse(anonymousClass) is StaticJSClass, true);
  expect(() => anonymousClass as StaticJSClass, returnsNormally);

  expect(staticJsClass is AnonymousClass, true);
  expect(confuse(staticJsClass) is AnonymousClass, true);
  expect(() => staticJsClass as AnonymousClass, returnsNormally);

  // With erasure, all static interop classes become the same type, so you can
  // cast either interop or native objects to them regardless of the underlying
  // class.
  expect(staticNativeClass is StaticJSClass, true);
  expect(confuse(staticNativeClass) is StaticJSClass, true);
  expect(() => staticNativeClass as StaticJSClass, returnsNormally);

  expect(staticJsClass is StaticNativeClass, true);
  expect(confuse(staticJsClass) is StaticNativeClass, true);
  expect(() => staticJsClass as StaticNativeClass, returnsNormally);

  expect(nativeClass is StaticJSClass, true);
  expect(confuse(nativeClass) is StaticJSClass, true);
  expect(() => nativeClass as StaticJSClass, returnsNormally);

  expect(jsClass is StaticNativeClass, true);
  expect(confuse(jsClass) is StaticNativeClass, true);
  expect(() => jsClass as StaticNativeClass, returnsNormally);

  expect(anonymousClass is StaticNativeClass, true);
  expect(confuse(anonymousClass) is StaticNativeClass, true);
  expect(() => anonymousClass as StaticNativeClass, returnsNormally);

  // You cannot, however, always cast from a static interop type to an interop
  // type or a native type. That will depend on whether the object is an interop
  // object or a native object.
  expect(staticNativeClass is JSClass, false);
  expect(confuse(staticNativeClass) is JSClass, false);
  // TODO(srujzs): This should throw in dart2js without the `confuse`, but it
  // does not. This does throw without `confuse` when we use an external
  // generative constructor for `StaticNativeClass`, but not when we use an
  // external factory constructor. Investigate why dart2js' type check
  // optimizations have this discrepancy.
  expect(() => confuse(staticNativeClass) as JSClass, throws);

  expect(staticNativeClass is AnonymousClass, false);
  expect(confuse(staticNativeClass) is AnonymousClass, false);
  // TODO(srujzs): Same comment as above.
  expect(() => confuse(staticNativeClass) as AnonymousClass, throws);

  expect(staticJsClass is NativeClass, false);
  expect(confuse(staticJsClass) is NativeClass, false);
  expect(() => staticJsClass as NativeClass, throws);

  // Subtyping rules.

  // Note that erasure ignores all static class type parameters so this
  // comparison becomes
  // `JavaScriptObject Function() is JavaScriptObject Function()`. This behavior
  // is similar to non-static interop classes.
  expect(
      returnGenericStaticJSClassInt is GenericStaticJSClass<String> Function(),
      true);
  expect(
      confuse(returnGenericStaticJSClassInt) is GenericStaticJSClass<String>
          Function(),
      true);
  expect(
      () => returnGenericStaticJSClassInt as GenericStaticJSClass<String>
          Function(),
      returnsNormally);

  // static interop class A <: static interop class A
  expect(returnStaticNativeClass is StaticNativeClass Function(), true);
  expect(
      confuse(returnStaticNativeClass) is StaticNativeClass Function(), true);
  expect(returnStaticJSClass is StaticJSClass Function(), true);
  expect(confuse(returnStaticJSClass) is StaticJSClass Function(), true);

  // static interop class A <: static interop class B
  expect(returnStaticNativeClass is StaticJSClass Function(), true);
  expect(confuse(returnStaticNativeClass) is StaticJSClass Function(), true);
  expect(returnStaticJSClass is StaticNativeClass Function(), true);
  expect(confuse(returnStaticJSClass) is StaticNativeClass Function(), true);

  // static interop class !<: native class
  expect(returnStaticNativeClass is NativeClass Function(), false);
  expect(confuse(returnStaticNativeClass) is NativeClass Function(), false);
  expect(returnStaticJSClass is NativeClass Function(), false);
  expect(confuse(returnStaticJSClass) is NativeClass Function(), false);

  // static interop class !<: package:js class
  expect(returnStaticNativeClass is JSClass Function(), false);
  expect(confuse(returnStaticNativeClass) is JSClass Function(), false);
  expect(returnStaticJSClass is JSClass Function(), false);
  expect(confuse(returnStaticJSClass) is JSClass Function(), false);

  // static interop class !<: anonymous class
  expect(returnStaticNativeClass is AnonymousClass Function(), false);
  expect(confuse(returnStaticNativeClass) is AnonymousClass Function(), false);
  expect(returnStaticJSClass is AnonymousClass Function(), false);
  expect(confuse(returnStaticJSClass) is AnonymousClass Function(), false);

  // native class <: static interop class
  expect(returnNativeClass is StaticJSClass Function(), true);
  expect(confuse(returnNativeClass) is StaticJSClass Function(), true);
  expect(returnNativeClass is StaticNativeClass Function(), true);
  expect(confuse(returnNativeClass) is StaticNativeClass Function(), true);

  // package:js class <: static interop class
  // TODO(46456): The runtime check using `confuse` does not fail, whereas the
  // compile-time check does on dart2js.
  // expect(returnJSClass is StaticJSClass Function(), true);
  expect(confuse(returnJSClass) is StaticJSClass Function(), true);
  // TODO(46456): The runtime check using `confuse` does not fail, whereas the
  // compile-time check does on dart2js.
  // expect(returnJSClass is StaticNativeClass Function(), true);
  expect(confuse(returnJSClass) is StaticNativeClass Function(), true);

  // anonymous class <: static interop class
  // TODO(46456): The runtime check using `confuse` does not fail, whereas the
  // compile-time check does on dart2js.
  // expect(returnAnonymousClass is StaticJSClass Function(), true);
  expect(confuse(returnAnonymousClass) is StaticJSClass Function(), true);
  // TODO(46456): The runtime check using `confuse` does not fail, whereas the
  // compile-time check does on dart2js.
  // expect(returnAnonymousClass is StaticNativeClass Function(), true);
  expect(confuse(returnAnonymousClass) is StaticNativeClass Function(), true);
}
