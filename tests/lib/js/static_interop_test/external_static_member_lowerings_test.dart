// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_static_member_lowerings_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
@staticInterop
class ExternalStatic {
  external factory ExternalStatic(String initialValue);
  external factory ExternalStatic.named(
      [String initialValue = 'uninitialized']);
  // External redirecting factories are not allowed.

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

extension on ExternalStatic {
  external String? get initialValue;
}

// Top-level fields.
@JS()
external String field;
@JS('field')
external String renamedField;
@JS()
external final String finalField;

// Top-level getters and setters.
@JS()
external String get getSet;
@JS()
external set getSet(String val);
@JS('getSet')
external String get renamedGetSet;
@JS('getSet')
external set renamedGetSet(String val);

// Top-level methods.
@JS()
external String method();
@JS()
external String differentArgsMethod(String a, [String b = '']);
@JS('method')
external String renamedMethod();

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic(initialValue) {
      this.initialValue = initialValue;
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

    globalThis.field = 'field';
    globalThis.finalField = 'finalField';
    globalThis.getSet = 'getSet';
    globalThis.method = function() {
      return 'method';
    }
    globalThis.differentArgsMethod = function(a, b) {
      return a + b;
    }
  ''');
  testClassStaticMembers();
  testTopLevelMembers();
  testFactories();
}

void testClassStaticMembers() {
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

void testTopLevelMembers() {
  // Fields.
  expect(field, 'field');
  field = 'modified';
  expect(field, 'modified');
  expect(renamedField, 'modified');
  renamedField = 'renamedField';
  expect(renamedField, 'renamedField');
  expect(finalField, 'finalField');

  // Getters and setters.
  expect(getSet, 'getSet');
  getSet = 'modified';
  expect(getSet, 'modified');
  expect(renamedGetSet, 'modified');
  renamedGetSet = 'renamedGetSet';
  expect(renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(method(), 'method');
  expect(differentArgsMethod('method'), 'methodundefined');
  expect(renamedMethod(), 'method');
}

void testFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = ExternalStatic(initialized);
  expect(externalStatic.initialValue, initialized);
  externalStatic = ExternalStatic.named();
  expect(externalStatic.initialValue, null);
}
