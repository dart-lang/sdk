// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS('library1.library2')
library external_static_member_with_namespaces_test;

import 'dart:js_interop';
import 'dart:js_util' as js_util;

import 'package:expect/minitest.dart';

@JS()
external dynamic eval(String code);

@JS('library3.ExternalStatic')
inline class ExternalStatic {
  final JSObject obj;
  external ExternalStatic();
  // TODO(srujzs): Uncomment the external factory test once the CFE supports
  // them.
  // external factory ExternalStatic.factory();
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
  // Use `callMethod` instead of top-level external to `eval` since the library
  // is namespaced.
  js_util.callMethod(js_util.globalThis, 'eval', [
    '''
    var library3 = {};
    var library2 = {library3: library3};
    var library1 = {library2: library2};
    globalThis.library1 = library1;

    library3.ExternalStatic = function ExternalStatic(a, b) {
      var len = arguments.length;
      this.a = len < 1 ? 0 : a;
      this.b = len < 2 ? '' : b;
    }
    library3.ExternalStatic.method = function() {
      return 'method';
    }
    library3.ExternalStatic.differentArgsMethod = function(a, b) {
      return a + b;
    }
    library3.ExternalStatic.field = 'field';
    library3.ExternalStatic.finalField = 'finalField';
    library3.ExternalStatic.getSet = 'getSet';
  ''']);

  // Constructors.
  void testExternalConstructorCall(ExternalStatic externalStatic) {
    expect(js_util.getProperty(externalStatic, 'a'), 0);
    expect(js_util.getProperty(externalStatic, 'b'), '');
  }
  testExternalConstructorCall(ExternalStatic());
  // testExternalConstructorCall(ExternalStatic.factory());
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

  // Methods and tear-offs.
  expect(ExternalStatic.method(), 'method');
  expect((ExternalStatic.method)(), 'method');
  expect(ExternalStatic.differentArgsMethod('method'), 'methodundefined');
  expect((ExternalStatic.differentArgsMethod)('optional', 'method'),
      'optionalmethod');
  expect(ExternalStatic.renamedMethod(), 'method');
  expect((ExternalStatic.renamedMethod)(), 'method');
}