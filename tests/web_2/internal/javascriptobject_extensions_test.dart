// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that JS objects can be referred to as extensions of JavaScriptObject.

@JS()
library javascriptobject_extensions_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:expect/minitest.dart';

import 'dart:html' show Window;
import 'dart:typed_data' show ByteBuffer;
import 'dart:_interceptors'
    show
        LegacyJavaScriptObject,
        JavaScriptObject,
        UnknownJavaScriptObject,
        JSObject;

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

@JS()
@anonymous
class AnonymousClass {
  external String get name;
}

class DartClass {}

external AnonymousClass get anonymousObj;

external ByteBuffer get arrayBuffer;

@JS('arrayBuffer')
external dynamic get arrayBufferDynamic;

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
    self.arrayBuffer = new ArrayBuffer();
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

  // Non-web Native classes like those in `dart:typed_data` are not subclasses
  // of JavaScriptObject.
  expect(arrayBuffer is JavaScriptObject, false);
  runtimeIsAndAs<JavaScriptObject>(arrayBuffer, false);
  runtimeIsAndAs<JavaScriptObject>(arrayBufferDynamic, false);
  expect(javaScriptObject is ByteBuffer, false);
  runtimeIsAndAs<ByteBuffer>(javaScriptObject, false);

  // Make sure `Object` methods work with JavaScriptObject like they do with JS
  // interop objects.
  expect(javaScriptObject == jsObj, true);
  expect(javaScriptObject.hashCode, isNotNull);
  expect(javaScriptObject.toString, isNotNull);
  expect(javaScriptObject.noSuchMethod, isNotNull);
  expect(javaScriptObject.runtimeType, isNotNull);

  // Transitive is and as.
  // JS type <: JavaScriptObject <: JSObject
  expect(jsObj is JSObject, true);
  runtimeIsAndAs<JSObject>(jsObj);
  // JavaScriptObject <: JS type <: Dart interface
  expect(javaScriptObject is InterfaceClass, true);
  runtimeIsAndAs<InterfaceClass>(javaScriptObject);
  // Dart implementation <: JS type <: JavaScriptObject
  var impl = ImplementationClass();
  expect(impl is JavaScriptObject, true);
  runtimeIsAndAs<JavaScriptObject>(impl);
  // Dart implementation <: JS type <: JavaScriptObject <: JSObject
  expect(impl is JSObject, true);
  runtimeIsAndAs<JSObject>(impl);

  // Test that JavaScriptObject can be used in place of package:js types in
  // function types, and vice versa.
  expect(returnJavaScriptObject is JSClass Function(), true);
  expect(returnJS is JavaScriptObject Function(), true);
  expect(returnJavaScriptObject is AnonymousClass Function(), true);
  expect(returnAnon is JavaScriptObject Function(), true);

  // Transitive subtyping.
  // UnknownJavaScriptObject <: JavaScriptObject <: JS type
  expect(returnUnknownJavaScriptObject is JSClass Function(), true);
  // JS type <: JavaScriptObject <: JSObject
  expect(returnJS is JSObject Function(), true);
  // JavaScriptObject <: JS type <: Dart interface
  expect(returnJavaScriptObject is InterfaceClass Function(), true);
  // Dart implementation <: JS type <: JavaScriptObject
  expect(returnImpl is JavaScriptObject Function(), true);
  // UnknownJavaScriptObject <: JavaScriptObject <: JS type <: Dart interface
  expect(returnUnknownJavaScriptObject is InterfaceClass Function(), true);
  // Dart implementation <: JS type <: JavaScriptObject <: JSObject
  expect(returnImpl is JSObject Function(), true);

  // Run above subtype checks but at runtime.
  expect(confuse(returnJavaScriptObject) is JSClass Function(), true);
  expect(confuse(returnJS) is JavaScriptObject Function(), true);
  expect(confuse(returnJavaScriptObject) is AnonymousClass Function(), true);
  expect(confuse(returnAnon) is JavaScriptObject Function(), true);

  expect(confuse(returnUnknownJavaScriptObject) is JSClass Function(), true);
  expect(confuse(returnJS) is JSObject Function(), true);
  expect(confuse(returnJavaScriptObject) is InterfaceClass Function(), true);
  expect(confuse(returnImpl) is JavaScriptObject Function(), true);
  expect(confuse(returnUnknownJavaScriptObject) is InterfaceClass Function(),
      true);
  expect(confuse(returnImpl) is JSObject Function(), true);
}
