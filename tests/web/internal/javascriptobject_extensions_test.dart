// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that JS objects can be referred to as extensions of JavaScriptObject.

@JS()
library javascriptobject_extensions_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:expect/expect.dart' show hasUnsoundNullSafety;
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

import 'dart:html' show Window;
import 'dart:_interceptors'
    show
        LegacyJavaScriptObject,
        JavaScriptObject,
        UnknownJavaScriptObject,
        JSObject;

const isDDC = const bool.fromEnvironment('dart.library._ddc_only');
const isDart2JS = const bool.fromEnvironment('dart.library._dart2js_only');

@JS()
external void eval(String code);

class InterfaceClass {}

@JS('JSClass')
class JSClass implements InterfaceClass {
  external JSClass();
  external String get name;
}

class ImplementationClass implements JSClass {
  String get name => 'ImplementationClass';
}

class GenericInterfaceClass<T> {}

@JS('JSClass')
class GenericJSClass<T> implements GenericInterfaceClass<T> {
  external GenericJSClass();
}

class GenericImplementationClass<T> implements GenericJSClass<T> {}

@JS()
@anonymous
class AnonymousClass {
  external String get name;
}

class DartClass {}

external AnonymousClass get anonymousObj;

external Window get window;

@JS('window')
external dynamic get windowDynamic;

// Extension on JavaScriptObject. In the future, when extension types are
// introduced, this will be explicitly disallowed.
extension JavaScriptObjectExtension on JavaScriptObject {
  // Use `className` instead so there's no ambiguity on what method is called.
  String get className => getProperty(this, 'name');
}

// Test runtime type checks and casts.
@pragma('dart2js:noInline')
void runtimeIsAndAs<T>(instance, [bool expectation = true]) {
  expect(instance is T, expectation);
  expect(() => instance as T, expectation ? returnsNormally : throws);
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

JavaScriptObject returnJavaScriptObject() => throw '';

JavaScriptObject? returnNullableJavaScriptObject() => throw '';

JSClass returnJS() => throw '';

AnonymousClass returnAnon() => throw '';

UnknownJavaScriptObject returnUnknownJavaScriptObject() => throw '';

ImplementationClass returnImpl() => throw '';

main() {
  eval(r'''
    function JSClass() {
      this.name = 'JSClass';
    }
    self.anonymousObj = {
      name: 'AnonymousClass',
    };
  ''');

  // Instances of JS classes can be casted to JavaScriptObject and back.
  var jsObj = JSClass();
  expect(jsObj is JavaScriptObject, true);
  runtimeIsAndAs<JavaScriptObject>(jsObj);
  var javaScriptObject = jsObj as JavaScriptObject;
  expect(javaScriptObject.className == 'JSClass', true);
  expect(javaScriptObject is JSClass, true);
  runtimeIsAndAs<JSClass>(javaScriptObject);

  // Object literals can be casted to JavaScriptObject and back.
  expect(anonymousObj is JavaScriptObject, true);
  runtimeIsAndAs<JavaScriptObject>(anonymousObj);
  javaScriptObject = anonymousObj as JavaScriptObject;
  expect(javaScriptObject.className == 'AnonymousClass', true);
  expect(javaScriptObject is AnonymousClass, true);
  runtimeIsAndAs<AnonymousClass>(javaScriptObject);

  // Dart objects that don't implement a JS type cannot be casted to or from
  // JavaScriptObject.
  var dartObj = DartClass();
  expect(dartObj is JavaScriptObject, false);
  runtimeIsAndAs<JavaScriptObject>(dartObj, false);
  expect(javaScriptObject is DartClass, false);
  runtimeIsAndAs<DartClass>(javaScriptObject, false);

  // Web Native classes are subclasses of JavaScriptObject, but not
  // LegacyJavaScriptObject.
  expect(window is JavaScriptObject, true);
  runtimeIsAndAs<JavaScriptObject>(window, true);
  runtimeIsAndAs<JavaScriptObject>(windowDynamic, true);
  javaScriptObject = jsObj as JavaScriptObject;
  expect(javaScriptObject is Window, false);
  runtimeIsAndAs<Window>(javaScriptObject, false);

  expect(window is LegacyJavaScriptObject, false);
  runtimeIsAndAs<LegacyJavaScriptObject>(window, false);
  runtimeIsAndAs<LegacyJavaScriptObject>(windowDynamic, false);
  var legacyJavaScriptObject = jsObj as LegacyJavaScriptObject;
  expect(legacyJavaScriptObject is Window, false);
  runtimeIsAndAs<Window>(legacyJavaScriptObject, false);

  // Make sure `Object` methods work with JavaScriptObject like they do with JS
  // interop objects.
  expect(javaScriptObject == jsObj, true);
  expect(javaScriptObject.hashCode, isNotNull);
  expect(javaScriptObject.toString, isNotNull);
  expect(javaScriptObject.noSuchMethod, isNotNull);
  expect(javaScriptObject.runtimeType, isNotNull);

  // Test that nullability works as expected.
  expect(null is JavaScriptObject?, true);
  runtimeIsAndAs<JavaScriptObject?>(null);
  expect(null is JavaScriptObject, false);
  runtimeIsAndAs<JavaScriptObject>(null, hasUnsoundNullSafety);

  // Most of the following tests don't work in DDC and dart2js. In order to test
  // the current status on both compilers, we place the current status in the
  // expectation, and the real expected value in a comment next to it. If at any
  // point we fix the compilers so we get the real expected value, the
  // corresponding expectations should be amended.

  // Transitive is and as.
  // JS type <: JavaScriptObject <: JSObject
  expect(jsObj is JSObject, true);
  runtimeIsAndAs<JSObject>(jsObj);
  // JavaScriptObject <: JS type <: Dart interface
  expect(jsObj is InterfaceClass, isDart2JS /* true */);
  runtimeIsAndAs<InterfaceClass>(jsObj, isDart2JS /* true */);
  // Generics should be effectively ignored when a JS interop class implements
  // a Dart class or vice versa.
  var jsObjInt = GenericJSClass<int>();
  expect(jsObjInt is GenericInterfaceClass<int>, isDart2JS /* true */);
  runtimeIsAndAs<GenericInterfaceClass<int>>(jsObjInt, isDart2JS /* true */);
  var jsObjString = GenericJSClass<String>();
  expect(jsObjString is GenericInterfaceClass<int>, isDart2JS /* true */);
  runtimeIsAndAs<GenericInterfaceClass<int>>(jsObjString, isDart2JS /* true */);
  expect(javaScriptObject is InterfaceClass, isDart2JS /* true */);
  runtimeIsAndAs<InterfaceClass>(javaScriptObject, isDart2JS /* true */);
  // Dart implementation <: JS type <: JavaScriptObject
  var impl = ImplementationClass();
  expect(impl is JSClass, true);
  runtimeIsAndAs<JSClass>(impl);
  var implInt = GenericImplementationClass<int>();
  expect(implInt is GenericJSClass<int>, true);
  runtimeIsAndAs<GenericJSClass<int>>(implInt);
  var implString = GenericImplementationClass<String>();
  expect(implString is GenericJSClass<int>, true);
  runtimeIsAndAs<GenericJSClass<int>>(implString);
  expect(impl is JavaScriptObject, false /* true */);
  runtimeIsAndAs<JavaScriptObject>(impl, false /* true */);
  // Dart implementation <: JS type <: JavaScriptObject <: JSObject
  expect(impl is JSObject, false /* true */);
  runtimeIsAndAs<JSObject>(impl, false /* true */);

  // Test that subtyping with nullability works as expected.
  expect(returnJavaScriptObject is JavaScriptObject? Function(), true);
  expect(returnNullableJavaScriptObject is JavaScriptObject Function(),
      hasUnsoundNullSafety);

  // Test that JavaScriptObject can be used in place of package:js types in
  // function types, and vice versa.
  // TODO(srujzs): We should add tests for subtyping involving generics in each
  // of these cases. However, it's very unlikely we'll fix the non-generic cases
  // to begin with, and such tests would be filtered today anyways, so we can
  // add those tests later if we do fix these.
  expect(returnJavaScriptObject is JSClass Function(), false /* true */);
  expect(returnJS is JavaScriptObject Function(), isDDC /* true */);
  expect(returnJavaScriptObject is AnonymousClass Function(), false /* true */);
  expect(returnAnon is JavaScriptObject Function(), isDDC /* true */);

  // Transitive subtyping.
  // UnknownJavaScriptObject <: JavaScriptObject <: JS type
  expect(returnUnknownJavaScriptObject is JSClass Function(), false /* true */);
  // JS type <: JavaScriptObject <: JSObject
  expect(returnJS is JSObject Function(), isDDC /* true */);
  // JavaScriptObject <: JS type <: Dart interface
  expect(returnJavaScriptObject is InterfaceClass Function(), false /* true */);
  // Dart implementation <: JS type <: JavaScriptObject
  expect(returnImpl is JavaScriptObject Function(), false /* true */);
  // UnknownJavaScriptObject <: JavaScriptObject <: JS type <: Dart interface
  expect(returnUnknownJavaScriptObject is InterfaceClass Function(),
      false /* true */);
  // Dart implementation <: JS type <: JavaScriptObject <: JSObject
  expect(returnImpl is JSObject Function(), false /* true */);

  // Run above subtype checks but at runtime.
  expect(confuse(returnJavaScriptObject) is JavaScriptObject? Function(), true);
  expect(confuse(returnNullableJavaScriptObject) is JavaScriptObject Function(),
      hasUnsoundNullSafety);

  expect(
      confuse(returnJavaScriptObject) is JSClass Function(), false /* true */);
  expect(confuse(returnJS) is JavaScriptObject Function(), true);
  expect(confuse(returnJavaScriptObject) is AnonymousClass Function(),
      false /* true */);
  expect(confuse(returnAnon) is JavaScriptObject Function(), true);

  expect(confuse(returnUnknownJavaScriptObject) is JSClass Function(),
      isDart2JS /* true */);
  expect(confuse(returnJS) is JSObject Function(), true);
  expect(confuse(returnJavaScriptObject) is InterfaceClass Function(),
      false /* true */);
  expect(confuse(returnImpl) is JavaScriptObject Function(), false /* true */);
  expect(confuse(returnUnknownJavaScriptObject) is InterfaceClass Function(),
      isDart2JS /* true */);
  expect(confuse(returnImpl) is JSObject Function(), false /* true */);
}
