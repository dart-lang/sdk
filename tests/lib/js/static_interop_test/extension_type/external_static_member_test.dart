// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srujzs): There's a decent amount of code duplication in this test. We
// should combine this with
// tests/lib/js/static_interop_test/external_static_member_lowerings_test.dart.

@JS()
library external_static_member_test;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

import 'external_static_member_with_namespaces.dart' as namespace;

@JS()
external void eval(String code);

@JS()
extension type ExternalStatic._(JSObject obj) implements JSObject {
  external ExternalStatic();
  external factory ExternalStatic.factory();
  external ExternalStatic.multipleArgs(double a, String b);
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
  @JS('method')
  external static String renamedMethod();
}

void testStaticMembers() {
  // Constructors.
  void testExternalConstructorCall(ExternalStatic externalStatic) {
    expect((externalStatic['a'] as JSNumber).toDartInt, 0);
    expect((externalStatic['b'] as JSString).toDart, '');
  }

  testExternalConstructorCall(ExternalStatic());
  testExternalConstructorCall(ExternalStatic.factory());
  testExternalConstructorCall(ExternalStatic.multipleArgs(0, ''));
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
  expect(ExternalStatic.renamedMethod(), 'method');
}

void testNamespacedStaticMembers() {
  // Constructors.
  void testExternalConstructorCall(namespace.ExternalStatic externalStatic) {
    expect((externalStatic['a'] as JSNumber).toDartInt, 0);
    expect((externalStatic['b'] as JSString).toDart, '');
  }

  testExternalConstructorCall(namespace.ExternalStatic());
  testExternalConstructorCall(namespace.ExternalStatic.factory());
  testExternalConstructorCall(namespace.ExternalStatic.multipleArgs(0, ''));
  testExternalConstructorCall(namespace.ExternalStatic.nonExternal());

  // Fields.
  expect(namespace.ExternalStatic.field, 'field');
  namespace.ExternalStatic.field = 'modified';
  expect(namespace.ExternalStatic.field, 'modified');
  expect(namespace.ExternalStatic.renamedField, 'modified');
  namespace.ExternalStatic.renamedField = 'renamedField';
  expect(namespace.ExternalStatic.renamedField, 'renamedField');
  expect(namespace.ExternalStatic.finalField, 'finalField');

  // Getters and setters.
  expect(namespace.ExternalStatic.getSet, 'getSet');
  namespace.ExternalStatic.getSet = 'modified';
  expect(namespace.ExternalStatic.getSet, 'modified');
  expect(namespace.ExternalStatic.renamedGetSet, 'modified');
  namespace.ExternalStatic.renamedGetSet = 'renamedGetSet';
  expect(namespace.ExternalStatic.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(namespace.ExternalStatic.method(), 'method');
  expect(namespace.ExternalStatic.renamedMethod(), 'method');
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
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic.finalField = 'finalField';
    globalThis.ExternalStatic.getSet = 'getSet';
  ''');
  testStaticMembers();
  eval('''
    var library3 = {};
    var library2 = {library3: library3};
    var library1 = {library2: library2};
    globalThis.library1 = library1;

    library3.ExternalStatic = globalThis.ExternalStatic;
    library3.ExternalStatic.field = 'field';
    library3.ExternalStatic.finalField = 'finalField';
    library3.ExternalStatic.getSet = 'getSet';
    delete globalThis.ExternalStatic;
  ''');
  testNamespacedStaticMembers();
}
