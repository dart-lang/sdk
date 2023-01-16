// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_static_member_lowerings_test;

import 'dart:_js_annotations';

import 'package:expect/minitest.dart';
import 'package:js/js.dart' show trustTypes;

@JS()
external dynamic eval(String code);

@JS()
@staticInterop
class ExternalStatic {
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

@JS('ExternalStatic')
@staticInterop
@trustTypes
class ExternalStaticTrustType {
  external static double field;
  external static double get getSet;
  external static double method();
}

// Top-level fields.
external String field;
@JS('field')
external String renamedField;
external final String finalField;

// Top-level getters and setters.
external String get getSet;
external set getSet(String val);
@JS('getSet')
external String get renamedGetSet;
@JS('getSet')
external set renamedGetSet(String val);

// Top-level methods.
external String method();
external String differentArgsMethod(String a, [String b = '']);
@JS('method')
external String renamedMethod();

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic() {}
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

  // Methods and tear-offs.
  expect(ExternalStatic.method(), 'method');
  expect((ExternalStatic.method)(), 'method');
  expect(ExternalStatic.differentArgsMethod('method'), 'method');
  expect((ExternalStatic.differentArgsMethod)('optional', 'method'),
      'optionalmethod');
  expect(ExternalStatic.renamedMethod(), 'method');
  expect((ExternalStatic.renamedMethod)(), 'method');

  // Use wrong return type in conjunction with `@trustTypes`.
  expect(ExternalStaticTrustType.field, 'renamedField');

  expect(ExternalStaticTrustType.getSet, 'renamedGetSet');

  expect(ExternalStaticTrustType.method(), 'method');
  expect((ExternalStaticTrustType.method)(), 'method');
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

  // Methods and tear-offs.
  expect(method(), 'method');
  expect((method)(), 'method');
  expect(differentArgsMethod('method'), 'method');
  expect((differentArgsMethod)('optional', 'method'), 'optionalmethod');
  expect(renamedMethod(), 'method');
  expect((renamedMethod)(), 'method');
}
