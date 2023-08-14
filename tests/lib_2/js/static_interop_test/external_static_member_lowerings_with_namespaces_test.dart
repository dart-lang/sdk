// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Like `external_static_member_lowerings_test.dart`, but uses the namespaces
// in the `@JS` annotations instead.

@JS('library1.library2')
library external_static_member_lowerings_with_namespaces_test;

import 'dart:js_interop';
import 'dart:js_util' as js_util;

import 'package:expect/minitest.dart';
import 'package:js/js.dart' show staticInterop;

@JS('library3.ExternalStatic')
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

void main() {
  // Use `callMethod` instead of top-level external to `eval` since the library
  // is namespaced.
  js_util.callMethod(js_util.globalThis, 'eval', [
    '''
    var library3 = {};
    var library2 = {library3: library3};
    var library1 = {library2: library2};
    globalThis.library1 = library1;

    library3.ExternalStatic = function ExternalStatic(initialValue) {
      this.initialValue = initialValue;
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

    library2.field = 'field';
    library2.getSet = 'getSet';
    library2.method = function() {
      return 'method';
    }
    library2.differentArgsMethod = function(a, b) {
      return a + b;
    }
    library3.namespacedField = 'namespacedField';
    library3.namespacedGetSet = 'namespacedGetSet';
    library3.namespacedMethod = function() {
      return 'namespacedMethod';
    }

  '''
  ]);
  testClassStaticMembers();
  testTopLevelMembers();
  testFactories();
}

// Top-level fields.
@JS()
external String field;
@JS('library3.namespacedField')
external String namespacedField;
@JS('field')
external final String finalField;

// Top-level getters and setters.
@JS()
external String get getSet;
@JS()
external set getSet(String val);
@JS('library3.namespacedGetSet')
external String get namespacedGetSet;
@JS('library3.namespacedGetSet')
external set namespacedGetSet(String val);

// Top-level methods.
@JS()
external String method();
@JS()
external String differentArgsMethod(String a, [String b = '']);
@JS('library3.namespacedMethod')
external String namespacedMethod();

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
  // Test a variety of renaming and namespacing to make sure we're handling '.'
  // correctly.
  // Fields.
  expect(field, 'field');
  field = 'modified';
  expect(field, 'modified');
  expect(namespacedField, 'namespacedField');
  namespacedField = 'modified';
  expect(namespacedField, 'modified');
  expect(finalField, 'modified');

  // Getters and setters.
  expect(getSet, 'getSet');
  getSet = 'modified';
  expect(getSet, 'modified');
  expect(namespacedGetSet, 'namespacedGetSet');
  namespacedGetSet = 'modified';
  expect(namespacedGetSet, 'modified');

  // Methods.
  expect(method(), 'method');
  expect(differentArgsMethod('method'), 'methodundefined');
  expect(namespacedMethod(), 'namespacedMethod');
}

void testFactories() {
  // Non-object literal factories.
  var initialized = 'initialized';

  var externalStatic = ExternalStatic(initialized);
  expect(externalStatic.initialValue, initialized);
  externalStatic = ExternalStatic.named();
  expect(externalStatic.initialValue, null);
}
