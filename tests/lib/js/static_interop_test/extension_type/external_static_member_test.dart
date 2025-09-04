// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srujzs): There's a decent amount of code duplication in this test. We
// should combine this with
// tests/lib/js/static_interop_test/external_static_member_lowerings_test.dart.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:expect/expect.dart';

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
  @JS('nestedField.foo.field')
  external static String nestedField;
  external static final String finalField;

  external static String get getSet;
  external static set getSet(String val);
  @JS('getSet')
  external static String get renamedGetSet;
  @JS('getSet')
  external static set renamedGetSet(String val);
  @JS('nestedGetSet.bar.getSet')
  external static String get nestedGetSet;
  @JS('nestedGetSet.bar.getSet')
  external static set nestedGetSet(String val);

  external static String method();
  @JS('method')
  external static String renamedMethod();
  @JS('nestedMethod.method')
  external static String nestedMethod();
}

void testStaticMembers() {
  // Constructors.
  void testExternalConstructorCall(ExternalStatic externalStatic) {
    Expect.equals(0, (externalStatic['a'] as JSNumber).toDartInt);
    Expect.equals('', (externalStatic['b'] as JSString).toDart);
  }

  testExternalConstructorCall(ExternalStatic());
  testExternalConstructorCall(ExternalStatic.factory());
  testExternalConstructorCall(ExternalStatic.multipleArgs(0, ''));
  testExternalConstructorCall(ExternalStatic.nonExternal());

  // Fields.
  Expect.equals('field', ExternalStatic.field);
  ExternalStatic.field = 'modified';
  Expect.equals('modified', ExternalStatic.field);
  Expect.equals('modified', ExternalStatic.renamedField);
  ExternalStatic.renamedField = 'renamedField';
  Expect.equals('renamedField', ExternalStatic.renamedField);
  Expect.equals('nestedField', ExternalStatic.nestedField);
  ExternalStatic.nestedField = 'modified';
  Expect.equals('modified', ExternalStatic.nestedField);
  Expect.equals('finalField', ExternalStatic.finalField);

  // Getters and setters.
  Expect.equals('getSet', ExternalStatic.getSet);
  ExternalStatic.getSet = 'modified';
  Expect.equals('modified', ExternalStatic.getSet);
  Expect.equals('modified', ExternalStatic.renamedGetSet);
  ExternalStatic.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', ExternalStatic.renamedGetSet);
  Expect.equals('nestedGetSet', ExternalStatic.nestedGetSet);
  ExternalStatic.nestedGetSet = 'modified';
  Expect.equals('modified', ExternalStatic.nestedGetSet);

  // Methods.
  Expect.equals('method', ExternalStatic.method());
  Expect.equals('method', ExternalStatic.renamedMethod());
  Expect.equals('nestedMethod', ExternalStatic.nestedMethod());
}

void testNamespacedStaticMembers() {
  // Constructors.
  void testExternalConstructorCall(namespace.ExternalStatic externalStatic) {
    Expect.equals(0, (externalStatic['a'] as JSNumber).toDartInt);
    Expect.equals('', (externalStatic['b'] as JSString).toDart);
  }

  testExternalConstructorCall(namespace.ExternalStatic());
  testExternalConstructorCall(namespace.ExternalStatic.factory());
  testExternalConstructorCall(namespace.ExternalStatic.multipleArgs(0, ''));
  testExternalConstructorCall(namespace.ExternalStatic.nonExternal());

  // Fields.
  Expect.equals('field', namespace.ExternalStatic.field);
  namespace.ExternalStatic.field = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.field);
  Expect.equals('modified', namespace.ExternalStatic.renamedField);
  namespace.ExternalStatic.renamedField = 'renamedField';
  Expect.equals('renamedField', namespace.ExternalStatic.renamedField);
  Expect.equals('nestedField', namespace.ExternalStatic.nestedField);
  namespace.ExternalStatic.nestedField = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.nestedField);
  Expect.equals('finalField', namespace.ExternalStatic.finalField);

  // Getters and setters.
  Expect.equals('getSet', namespace.ExternalStatic.getSet);
  namespace.ExternalStatic.getSet = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.getSet);
  Expect.equals('modified', namespace.ExternalStatic.renamedGetSet);
  namespace.ExternalStatic.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', namespace.ExternalStatic.renamedGetSet);
  Expect.equals('nestedGetSet', namespace.ExternalStatic.nestedGetSet);
  namespace.ExternalStatic.nestedGetSet = 'modified';
  Expect.equals('modified', namespace.ExternalStatic.nestedGetSet);

  // Methods.
  Expect.equals('method', namespace.ExternalStatic.method());
  Expect.equals('method', namespace.ExternalStatic.renamedMethod());
  Expect.equals('nestedMethod', namespace.ExternalStatic.nestedMethod());
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
    globalThis.ExternalStatic.nestedMethod = {
      method: function() {
        return 'nestedMethod';
      }
    };
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic.nestedField = {
      foo: {
        field: 'nestedField'
      }
    };
    globalThis.ExternalStatic.finalField = 'finalField';
    globalThis.ExternalStatic.nestedGetSet = {
      bar: {
        getSet: 'nestedGetSet'
      }
    };
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
    library3.ExternalStatic.nestedField.foo.field = 'nestedField';
    library3.ExternalStatic.finalField = 'finalField';
    library3.ExternalStatic.getSet = 'getSet';
    library3.ExternalStatic.nestedGetSet.bar.getSet = 'nestedGetSet';
    delete globalThis.ExternalStatic;
  ''');
  testNamespacedStaticMembers();
}
