// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'package:expect/expect.dart';

import 'external_static_member_lowerings_with_namespaces.dart' as namespace;

@JS()
external void eval(String code);

@JS()
@staticInterop
class ExternalStatic {
  external factory ExternalStatic(String initialValue);
  external factory ExternalStatic.named([
    String initialValue = 'uninitialized',
  ]);
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
  Expect.equals('field', ExternalStatic.field);
  ExternalStatic.field = 'modified';
  Expect.equals('modified', ExternalStatic.field);
  Expect.equals('modified', ExternalStatic.renamedField);
  ExternalStatic.renamedField = 'renamedField';
  Expect.equals('renamedField', ExternalStatic.renamedField);
  Expect.equals('finalField', ExternalStatic.finalField);

  // Getters and setters.
  Expect.equals('getSet', ExternalStatic.getSet);
  ExternalStatic.getSet = 'modified';
  Expect.equals('modified', ExternalStatic.getSet);
  Expect.equals('modified', ExternalStatic.renamedGetSet);
  ExternalStatic.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', ExternalStatic.renamedGetSet);

  // Methods.
  Expect.equals('method', ExternalStatic.method());
  Expect.equals('method', ExternalStatic.renamedMethod());
}

void testTopLevelMembers() {
  // Fields.
  Expect.equals('field', field);
  field = 'modified';
  Expect.equals('modified', field);
  Expect.equals('modified', renamedField);
  renamedField = 'renamedField';
  Expect.equals('renamedField', renamedField);
  Expect.equals('finalField', finalField);

  // Getters and setters.
  Expect.equals('getSet', getSet);
  getSet = 'modified';
  Expect.equals('modified', getSet);
  Expect.equals('modified', renamedGetSet);
  renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', renamedGetSet);

  // Methods.
  Expect.equals('method', method());
  Expect.equals('method', renamedMethod());
}

void testFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = ExternalStatic(initialized);
  Expect.equals(initialized, externalStatic.initialValue);
  externalStatic = ExternalStatic.named();
  Expect.isNull(externalStatic.initialValue);
}

void testNamespacedClassStaticMembers() {
  // Fields.
  Expect.equals('field', namespace.ExternalStatic.field);
  namespace.ExternalStatic.field = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.field);
  Expect.equals('modified', namespace.ExternalStatic.renamedField);
  namespace.ExternalStatic.renamedField = 'renamedField';
  Expect.equals('renamedField', namespace.ExternalStatic.renamedField);
  Expect.equals('finalField', namespace.ExternalStatic.finalField);

  // Getters and setters.
  Expect.equals('getSet', namespace.ExternalStatic.getSet);
  namespace.ExternalStatic.getSet = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.getSet);
  Expect.equals('modified', namespace.ExternalStatic.renamedGetSet);
  namespace.ExternalStatic.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', namespace.ExternalStatic.renamedGetSet);

  // Methods.
  Expect.equals('method', namespace.ExternalStatic.method());
  Expect.equals('method', namespace.ExternalStatic.renamedMethod());
}

void testNamespacedTopLevelMembers() {
  // Fields.
  Expect.equals('field', namespace.field);
  namespace.field = 'modified';
  Expect.equals('modified', namespace.field);
  Expect.equals('modified', namespace.renamedField);
  namespace.renamedField = 'renamedField';
  Expect.equals('renamedField', namespace.renamedField);
  Expect.equals('finalField', namespace.finalField);

  // Getters and setters.
  Expect.equals('getSet', namespace.getSet);
  namespace.getSet = 'modified';
  Expect.equals('modified', namespace.getSet);
  Expect.equals('modified', namespace.renamedGetSet);
  namespace.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', namespace.renamedGetSet);

  // Methods.
  Expect.equals('method', namespace.method());
  Expect.equals('method', namespace.renamedMethod());
}

void testNamespacedFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = namespace.ExternalStatic(initialized);
  Expect.equals(initialized, externalStatic.initialValue);
  externalStatic = namespace.ExternalStatic.named();
  Expect.isNull(externalStatic.initialValue);
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
