// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that a static interop class can be used in place of a Native class and
// its static members work as expected post-erasure.

@JS()
library use_erased_type_members_test;

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

@JS()
@staticInterop
class Parent {}

extension ParentExtension on Parent {
  external String get parentExternalGetSet;
  external set parentExternalGetSet(String val);
  external String parentExternalMethod();

  String get parentGetSet => this.parentExternalGetSet;
  set parentGetSet(String val) => this.parentExternalGetSet = val;
  String parentMethod() => 'parentMethod';
}

@JS()
@staticInterop
class Interface {}

extension InterfaceExtension on Interface {
  external String get interfaceExternalGetSet;
  external set interfaceExternalGetSet(String val);
  external String interfaceExternalMethod();

  String get interfaceGetSet => this.interfaceExternalGetSet;
  set interfaceGetSet(String val) => this.interfaceExternalGetSet = val;
  String interfaceMethod() => 'interfaceMethod';
}

@JS('NativeClass')
@staticInterop
class StaticJSClass extends Parent implements Interface {
  external factory StaticJSClass();
  external factory StaticJSClass.externalFactory();
  factory StaticJSClass.redirectingFactory() = StaticJSClass;

  external static String get externalStaticGetSet;
  external static set externalStaticGetSet(String val);
  external static String externalStaticMethod();
}

extension StaticJSClassExtension on StaticJSClass {
  external String get externalGetSet;
  external set externalGetSet(String val);
  external String externalMethod();

  String get getSet => this.externalGetSet;
  set getSet(String val) => this.externalGetSet = val;
  String method() => 'method';
}

void main() {
  nativeTesting();
  native_testing.JS('', r'''
    (function(){
      function NativeClass() {
        this.externalGetSet = '';
        this.externalMethod = function() { return 'externalMethod'; };

        this.parentExternalGetSet = '';
        this.parentExternalMethod = function() {
          return 'parentExternalMethod';
        };

        this.interfaceExternalGetSet = '';
        this.interfaceExternalMethod = function() {
          return 'interfaceExternalMethod';
        };
      }
      NativeClass.externalStaticField = 'externalStaticField';
      NativeClass.externalStaticGetSet = NativeClass.externalStaticField;
      NativeClass.externalStaticMethod = function() {
        return 'externalStaticMethod';
      };
      self.NativeClass = NativeClass;
      self.makeNativeClass = function(){return new NativeClass()};
      self.nativeConstructor(NativeClass);
    })()
  ''');
  applyTestExtensions(['NativeClass']);

  // NativeClass needs to be live, so it can be correctly intercepted.
  NativeClass();
  // Invoke constructors and ensure they're typed correctly.
  StaticJSClass staticJs = StaticJSClass();
  staticJs = StaticJSClass.externalFactory();
  staticJs = StaticJSClass.redirectingFactory();

  // Invoke external static members.
  StaticJSClass.externalStaticGetSet = 'externalStaticGetSet';
  expect(StaticJSClass.externalStaticGetSet, 'externalStaticGetSet');
  expect(StaticJSClass.externalStaticMethod(), 'externalStaticMethod');

  // Use extension members.
  staticJs.externalGetSet = 'externalGetSet';
  expect(staticJs.externalGetSet, 'externalGetSet');
  expect(staticJs.externalMethod(), 'externalMethod');

  staticJs.getSet = 'getSet';
  expect(staticJs.getSet, 'getSet');
  expect(staticJs.method(), 'method');

  // Use parent extension members.
  staticJs.parentExternalGetSet = 'parentExternalGetSet';
  expect(staticJs.parentExternalGetSet, 'parentExternalGetSet');
  expect(staticJs.parentExternalMethod(), 'parentExternalMethod');

  staticJs.parentGetSet = 'parentGetSet';
  expect(staticJs.parentGetSet, 'parentGetSet');
  expect(staticJs.parentMethod(), 'parentMethod');

  // Use interface extension members.
  staticJs.interfaceExternalGetSet = 'interfaceExternalGetSet';
  expect(staticJs.interfaceExternalGetSet, 'interfaceExternalGetSet');
  expect(staticJs.interfaceExternalMethod(), 'interfaceExternalMethod');

  staticJs.interfaceGetSet = 'interfaceGetSet';
  expect(staticJs.interfaceGetSet, 'interfaceGetSet');
  expect(staticJs.interfaceMethod(), 'interfaceMethod');
}
