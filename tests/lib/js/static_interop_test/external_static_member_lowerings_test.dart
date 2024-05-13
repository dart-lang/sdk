// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_static_member_lowerings_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

import 'external_static_member_lowerings_with_namespaces.dart' as namespace;

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
@JS('method')
external String renamedMethod();

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

void testNamespacedClassStaticMembers() {
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

void testNamespacedTopLevelMembers() {
  // Fields.
  expect(namespace.field, 'field');
  namespace.field = 'modified';
  expect(namespace.field, 'modified');
  expect(namespace.renamedField, 'modified');
  namespace.renamedField = 'renamedField';
  expect(namespace.renamedField, 'renamedField');
  expect(namespace.finalField, 'finalField');

  // Getters and setters.
  expect(namespace.getSet, 'getSet');
  namespace.getSet = 'modified';
  expect(namespace.getSet, 'modified');
  expect(namespace.renamedGetSet, 'modified');
  namespace.renamedGetSet = 'renamedGetSet';
  expect(namespace.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(namespace.method(), 'method');
  expect(namespace.renamedMethod(), 'method');
}

void testNamespacedFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = namespace.ExternalStatic(initialized);
  expect(externalStatic.initialValue, initialized);
  externalStatic = namespace.ExternalStatic.named();
  expect(externalStatic.initialValue, null);
}

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic(initialValue) {
      this.initialValue = initialValue;
    }
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic.finalField = 'finalField';
    globalThis.ExternalStatic.getSet = 'getSet';
    globalThis.ExternalStatic.method = function() {
      return 'method';
    }

    globalThis.field = 'field';
    globalThis.finalField = 'finalField';
    globalThis.getSet = 'getSet';
    globalThis.method = function() {
      return 'method';
    }
  ''');
  testClassStaticMembers();
  testTopLevelMembers();
  testFactories();
  // Move declarations to a namespace and delete the top-level ones to test that
  // we use the declaration's enclosing library's annotation and not the current
  // library's.
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
    library3.field = 'field';
    library3.finalField = 'finalField';
    library3.getSet = 'getSet';
    library3.method = globalThis.method;
    delete globalThis.field;
    delete globalThis.finalField;
    delete globalThis.getSet;
    delete globalThis.method;
  ''');
  testNamespacedClassStaticMembers();
  testNamespacedTopLevelMembers();
  testNamespacedFactories();
}
