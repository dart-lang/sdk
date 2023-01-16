// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_static_member_lowerings_test;

import 'dart:_js_annotations';
import 'dart:js_util' as js_util;

import 'package:expect/minitest.dart';
import 'package:js/js.dart' show trustTypes;

@JS()
external dynamic eval(String code);

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
  external String get initialValue;
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

@JS()
@staticInterop
@anonymous
class Anonymous {
  external factory Anonymous({bool? a, bool b = true, bool? c = null});
  external factory Anonymous.named({bool? a, bool b = true, bool? c = null});
  external factory Anonymous.map({Map<String, String>? map});
  external factory Anonymous.nestedAnonymous({Anonymous? anonymous});
}

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

void testFactories() {
  // Non-object literal factories and their tear-offs.
  var initialized = 'initialized';
  var uninitialized = 'uninitialized';

  var externalStatic = ExternalStatic(initialized);
  expect(externalStatic.initialValue, initialized);
  externalStatic = ExternalStatic.named();
  expect(externalStatic.initialValue, uninitialized);

  externalStatic = (ExternalStatic.new)(initialized);
  expect(externalStatic.initialValue, initialized);
  externalStatic = (ExternalStatic.named)(initialized);
  expect(externalStatic.initialValue, initialized);

  // Object literal factories.
  void testHasProps(Anonymous obj,
      {bool a = false, bool b = false, bool c = false}) {
    expect(js_util.hasProperty(obj, 'a'), a);
    expect(js_util.hasProperty(obj, 'b'), b);
    expect(js_util.hasProperty(obj, 'c'), c);
  }

  testHasProps(Anonymous());
  testHasProps(Anonymous(a: true), a: true);
  testHasProps(Anonymous(b: true), b: true);
  testHasProps(Anonymous(c: true), c: true);
  testHasProps(Anonymous(a: true, b: true), a: true, b: true);
  testHasProps(Anonymous(a: true, c: true), a: true, c: true);
  testHasProps(Anonymous(b: true, c: true), b: true, c: true);
  testHasProps(Anonymous(a: true, b: true, c: true), a: true, b: true, c: true);

  testHasProps(Anonymous.named());
  testHasProps(Anonymous.named(a: true), a: true);
  testHasProps(Anonymous.named(b: true), b: true);
  testHasProps(Anonymous.named(c: true), c: true);
  testHasProps(Anonymous.named(a: true, b: true), a: true, b: true);
  testHasProps(Anonymous.named(a: true, c: true), a: true, c: true);
  testHasProps(Anonymous.named(b: true, c: true), b: true, c: true);
  testHasProps(Anonymous.named(a: true, b: true, c: true),
      a: true, b: true, c: true);

  // Test that `jsify` is called by checking to see if Map is converted to an
  // object literal and that we transform subnodes.
  var nested =
      Anonymous.nestedAnonymous(anonymous: Anonymous.map(map: {'key': 'val'}));
  var anonymous = js_util.getProperty(nested, 'anonymous');
  expect(anonymous is Anonymous, true);
  expect(js_util.getProperty(anonymous, 'map') is Map<String, String>, false);
}
