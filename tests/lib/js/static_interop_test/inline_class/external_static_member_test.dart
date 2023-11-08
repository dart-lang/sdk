// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library external_static_member_test;

import 'dart:js_interop';
import 'dart:js_util' as js_util;

import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
extension type ExternalStatic._(JSObject obj) {
  external ExternalStatic();
  external factory ExternalStatic.factory();
  external ExternalStatic.multipleArgs(double a, String b);
  external ExternalStatic.differentArgs(double a, [String b = '']);
  ExternalStatic.nonExternal() : this.obj = ExternalStatic() as JSObject;

  external static String field;
  @JS('field')
  external static String renamedField;
  external static final String finalField;

  external static String get getSet;
  external static set getSet(String val);
  @JS('getSet')
  external static String get renamedGetSet;
  @JS('getSet')
  external static set renamedGetSet(String val);

  external static String method();
  external static String differentArgsMethod(String a, [String b = '']);
  @JS('method')
  external static String renamedMethod();
}

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic(a, b) {
      var len = arguments.length;
      this.a = len < 1 ? 0 : a;
      this.b = len < 2 ? '' : b;
    }
    globalThis.ExternalStatic.method = function() {
      return 'method';
    }
    globalThis.ExternalStatic.differentArgsMethod = function(a, b) {
      return a + b;
    }
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic.finalField = 'finalField';
    globalThis.ExternalStatic.getSet = 'getSet';
  ''');

  // Constructors.
  void testExternalConstructorCall(ExternalStatic externalStatic) {
    expect(js_util.getProperty(externalStatic, 'a'), 0);
    expect(js_util.getProperty(externalStatic, 'b'), '');
  }

  testExternalConstructorCall(ExternalStatic());
  testExternalConstructorCall(ExternalStatic.factory());
  testExternalConstructorCall(ExternalStatic.multipleArgs(0, ''));
  testExternalConstructorCall(ExternalStatic.differentArgs(0));
  testExternalConstructorCall(ExternalStatic.nonExternal());

  // Fields.
  expect(ExternalStatic.field, 'field');
  ExternalStatic.field = 'modified';
  expect(ExternalStatic.field, 'modified');
  expect(ExternalStatic.renamedField, 'modified');
  ExternalStatic.renamedField = 'renamedField';
  expect(ExternalStatic.renamedField, 'renamedField');
  expect(ExternalStatic.finalField, 'finalField');

  // Getters and setters.
  expect(ExternalStatic.getSet, 'getSet');
  ExternalStatic.getSet = 'modified';
  expect(ExternalStatic.getSet, 'modified');
  expect(ExternalStatic.renamedGetSet, 'modified');
  ExternalStatic.renamedGetSet = 'renamedGetSet';
  expect(ExternalStatic.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(ExternalStatic.method(), 'method');
  expect(ExternalStatic.differentArgsMethod('method'), 'methodundefined');
  expect(ExternalStatic.renamedMethod(), 'method');
}
