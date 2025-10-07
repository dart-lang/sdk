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
  @JS('nested-field.foo.field')
  external static String nestedField;
  external static final String finalField;

  external static String get getSet;
  external static set getSet(String val);
  @JS('getSet')
  external static String get renamedGetSet;
  @JS('getSet')
  external static set renamedGetSet(String val);
  @JS('nestedGetSet.1.getSet')
  external static String get nestedGetSet;
  @JS('nestedGetSet.1.getSet')
  external static set nestedGetSet(String val);

  external static String method();
  @JS('method')
  external static String renamedMethod();
  @JS('nested^method.method')
  external static String nestedMethod();
}

extension on ExternalStatic {
  external String? get initialValue;
}

@JS('External-Static')
@staticInterop
class ExternalStaticRenamed implements ExternalStatic {
  external factory ExternalStaticRenamed();
}

// Top-level fields.
@JS()
external String field;
@JS('field')
external String renamedField;
@JS('nested-field.foo.field')
external String nestedField;
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
@JS('nestedGetSet.1.getSet')
external String get nestedGetSet;
@JS('nestedGetSet.1.getSet')
external set nestedGetSet(String val);

// Top-level methods.
@JS()
external String method();
@JS('method')
external String renamedMethod();
@JS('nested^method.method')
external String nestedMethod();

void testClassStaticMembers() {
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

void testTopLevelMembers() {
  // Fields.
  Expect.equals('field', field);
  field = 'modified';
  Expect.equals('modified', field);
  Expect.equals('modified', renamedField);
  renamedField = 'renamedField';
  Expect.equals('renamedField', renamedField);
  Expect.equals('nestedField', nestedField);
  nestedField = 'modified';
  Expect.equals('modified', nestedField);
  Expect.equals('finalField', finalField);

  // Getters and setters.
  Expect.equals('getSet', getSet);
  getSet = 'modified';
  Expect.equals('modified', getSet);
  Expect.equals('modified', renamedGetSet);
  renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', renamedGetSet);
  Expect.equals('nestedGetSet', nestedGetSet);
  nestedGetSet = 'modified';
  Expect.equals('modified', nestedGetSet);

  // Methods.
  Expect.equals('method', method());
  Expect.equals('method', renamedMethod());
  Expect.equals('nestedMethod', nestedMethod());
}

void testFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = ExternalStatic(initialized);
  Expect.equals(initialized, externalStatic.initialValue);
  externalStatic = ExternalStatic.named();
  Expect.isNull(externalStatic.initialValue);
  externalStatic = ExternalStaticRenamed();
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

void testNamespacedTopLevelMembers() {
  // Fields.
  Expect.equals('field', namespace.field);
  namespace.field = 'modified';
  Expect.equals('modified', namespace.field);
  Expect.equals('modified', namespace.renamedField);
  namespace.renamedField = 'renamedField';
  Expect.equals('renamedField', namespace.renamedField);
  Expect.equals('nestedField', namespace.nestedField);
  namespace.nestedField = 'modified';
  Expect.equals('modified', namespace.nestedField);
  Expect.equals('finalField', namespace.finalField);

  // Getters and setters.
  Expect.equals('getSet', namespace.getSet);
  namespace.getSet = 'modified';
  Expect.equals('modified', namespace.getSet);
  Expect.equals('modified', namespace.renamedGetSet);
  namespace.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', namespace.renamedGetSet);
  Expect.equals('nestedGetSet', namespace.nestedGetSet);
  namespace.nestedGetSet = 'modified';
  Expect.equals('modified', namespace.nestedGetSet);

  // Methods.
  Expect.equals('method', namespace.method());
  Expect.equals('method', namespace.renamedMethod());
  Expect.equals('nestedMethod', namespace.nestedMethod());
}

void testNamespacedFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = namespace.ExternalStatic(initialized);
  Expect.equals(initialized, externalStatic.initialValue);
  externalStatic = namespace.ExternalStatic.named();
  Expect.isNull(externalStatic.initialValue);
  externalStatic = namespace.ExternalStaticRenamed();
  Expect.isNull(externalStatic.initialValue);
}

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic(initialValue) {
      this.initialValue = initialValue;
    }
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic['nested-field'] = {
      foo: {
        field: 'nestedField'
      }
    };
    globalThis.ExternalStatic.finalField = 'finalField';
    globalThis.ExternalStatic.getSet = 'getSet';
    globalThis.ExternalStatic.nestedGetSet = {
      '1': {
        getSet: 'nestedGetSet'
      }
    };
    globalThis.ExternalStatic.method = function() {
      return 'method';
    }
    globalThis.ExternalStatic['nested^method'] = {
      method: function() {
        return 'nestedMethod';
      }
    };
    globalThis['External-Static'] = globalThis.ExternalStatic;

    globalThis.field = 'field';
    globalThis['nested-field'] = {
      foo: {
        field: 'nestedField'
      }
    };
    globalThis.finalField = 'finalField';
    globalThis.getSet = 'getSet';
    globalThis.nestedGetSet = {
      '1': {
        getSet: 'nestedGetSet'
      }
    };
    globalThis.method = function() {
      return 'method';
    }
    globalThis['nested^method'] = {
      method: function() {
        return 'nestedMethod';
      }
    };
  ''');
  testClassStaticMembers();
  testTopLevelMembers();
  testFactories();
  // Move declarations to a namespace and delete the top-level ones to test that
  // we use the declaration's enclosing library's annotation and not the current
  // library's.
  eval('''
    var library3 = {};
    var library2 = {'library*3': library3};
    var library1 = {library2: library2};
    globalThis['library-1'] = library1;

    library3.ExternalStatic = globalThis.ExternalStatic;
    library3.ExternalStatic.field = 'field';
    library3.ExternalStatic['nested-field'].foo.field = 'nestedField';
    library3.ExternalStatic.finalField = 'finalField';
    library3.ExternalStatic.getSet = 'getSet';
    library3.ExternalStatic.nestedGetSet['1'].getSet = 'nestedGetSet';
    library2['External-Static'] = globalThis.ExternalStatic;
    delete globalThis.ExternalStatic;
    library3.field = 'field';
    library3['nested-field'] = {
      foo: {
        field: 'nestedField'
      }
    };
    library3.finalField = 'finalField';
    library3.getSet = 'getSet';
    library3.nestedGetSet = {
      '1': {
        getSet: 'nestedGetSet'
      }
    };
    library3.method = globalThis.method;
    library3['nested^method'] = globalThis['nested^method'];
    delete globalThis.field;
    delete globalThis.finalField;
    delete globalThis.getSet;
    delete globalThis.method;
  ''');
  testNamespacedClassStaticMembers();
  testNamespacedTopLevelMembers();
  testNamespacedFactories();
}
