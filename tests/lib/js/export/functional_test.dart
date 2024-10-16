// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various uses of exports that are returned from `createDartExport` or
// `createJSInteropWrapper`.

import 'dart:js_interop';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js_util.dart';

// Test exporting all vs. only some members.
@JSExport()
class ExportAll {
  ExportAll.constructor();
  factory ExportAll.factory() => ExportAll.constructor();

  String field = 'field';
  final String finalField = 'finalField';
  String _getSetField = 'getSet';
  String get getSet => _getSetField;
  set getSet(String val) => _getSetField = val;
  String method() => 'method';

  static String staticField = throw '';
  static void staticMethod() => throw '';
}

extension on ExportAll {
  String extensionMethod() => throw '';

  static String extensionStaticField = throw '';
  static void extensionStaticMethod() => throw '';
}

void testExportAll(WrapperCreator creator) {
  var dartInstance = ExportAll.constructor();
  var all = creator.createExportAll(dartInstance);

  // Verify only the exportable properties exist.
  expect(hasProperty(all, 'constructor'), false);
  expect(hasProperty(all, 'factory'), false);
  expect(hasProperty(all, 'field'), true);
  expect(hasProperty(all, 'finalField'), true);
  expect(hasProperty(all, '_getSetField'), true);
  expect(hasProperty(all, 'getSet'), true);
  expect(hasProperty(all, 'method'), true);
  expect(hasProperty(all, 'staticField'), false);
  expect(hasProperty(all, 'staticMethod'), false);
  expect(hasProperty(all, 'extensionMethod'), false);
  expect(hasProperty(all, 'extensionStaticField'), false);
  expect(hasProperty(all, 'extensionStaticMethod'), false);
}

class ExportSome {
  ExportSome.constructor();
  factory ExportSome.factory() => ExportSome.constructor();

  @JSExport()
  String field = 'field';
  @JSExport()
  final String finalField = 'finalField';
  @JSExport()
  String get getSet => nonExportField;
  @JSExport()
  set getSet(String val) => nonExportField = val;
  @JSExport()
  String method() => 'method';

  String nonExportField = 'getSet';
  final String nonExportFinalField = '';
  String get nonExportGetSet => throw '';
  set nonExportGetSet(String val) => throw '';
  String nonExportMethod() => throw '';
}

void testExportSome(WrapperCreator creator) {
  var dartInstance = ExportSome.constructor();
  var some = creator.createExportSome(dartInstance);

  // Verify only the properties we marked as exportable exist.
  expect(hasProperty(some, 'constructor'), false);
  expect(hasProperty(some, 'factory'), false);

  expect(hasProperty(some, 'field'), true);
  expect(hasProperty(some, 'finalField'), true);
  expect(hasProperty(some, 'getSet'), true);
  expect(hasProperty(some, 'method'), true);

  expect(hasProperty(some, 'nonExportField'), false);
  expect(hasProperty(some, 'nonExportFinalField'), false);
  expect(hasProperty(some, 'nonExportGetSet'), false);
  expect(hasProperty(some, 'nonExportMethod'), false);
}

// Test that the properties are forwarded correctly in the object literal.
void testForwarding(WrapperCreator creator) {
  var dartInstance = ExportAll.constructor();
  var all = creator.createExportAll(dartInstance);

  expect(getProperty(all, 'field'), dartInstance.field);
  setProperty(all, 'field', 'modified');
  expect(dartInstance.field, 'modified');

  expect(getProperty(all, 'finalField'), dartInstance.finalField);

  expect(getProperty(all, 'getSet'), dartInstance.getSet);
  setProperty(all, 'getSet', 'modified');
  expect(dartInstance.getSet, 'modified');

  expect(callMethod(all, 'method', []), dartInstance.method());
}

// Test inheritance and overrides for every kind of member.
@JSExport()
class Superclass {
  String field = 'superclassField';
  final String finalField = 'superclassFinalField';
  String get getSet => 'superclassGetter';
  set getSet(String val) {
    if (val != 'superclassSetter') throw '';
  }

  String method() => 'superclassMethod';

  String nonOverriddenMethod() => 'nonOverriddenMethod';
}

@JSExport()
class Inheritance extends Superclass {}

void testInheritance(WrapperCreator creator) {
  var dartInheritance = Inheritance();
  var inheritance = creator.createInheritance(dartInheritance);

  expect(getProperty(inheritance, 'field'), dartInheritance.field);
  setProperty(inheritance, 'field', 'modified');
  expect(dartInheritance.field, 'modified');

  expect(getProperty(inheritance, 'finalField'), dartInheritance.finalField);

  expect(getProperty(inheritance, 'getSet'), dartInheritance.getSet);
  setProperty(inheritance, 'getSet', 'superclassSetter');

  expect(callMethod(inheritance, 'method', []), dartInheritance.method());
}

@JSExport()
class Overrides extends Superclass {
  String field = 'derivedField';
  final String finalField = 'derivedFinalField';
  String get getSet => 'derivedGetter';
  set getSet(String val) {
    if (val != 'derivedSetter') throw '';
  }

  String method() => 'derivedMethod';
}

void testOverrides(WrapperCreator creator) {
  var dartOverrides = Overrides();
  var overrides = creator.createOverrides(dartOverrides);

  expect(getProperty(overrides, 'field'), dartOverrides.field);
  setProperty(overrides, 'field', 'modified');
  expect(dartOverrides.field, 'modified');

  expect(getProperty(overrides, 'finalField'), dartOverrides.finalField);

  expect(getProperty(overrides, 'getSet'), dartOverrides.getSet);
  setProperty(overrides, 'getSet', 'derivedSetter');

  expect(callMethod(overrides, 'method', []), dartOverrides.method());
  expect(callMethod(overrides, 'nonOverriddenMethod', []),
      dartOverrides.nonOverriddenMethod());
}

// Test case where some members are overridden by members not marked for export,
// essentially removing them.
class SuperclassShadowed {
  @JSExport()
  String field = 'superclassField';
  final String finalField = '';
  @JSExport()
  String get getSet => 'superclassGetter';
  set getSet(String val) {}

  @JSExport()
  String method() => 'superclassMethod';
}

class InheritanceShadowed extends SuperclassShadowed {
  String field = 'derivedField';
  String get getSet => 'derivedGetter';
  @JSExport()
  String method() => 'derivedMethod';
}

void testShadowed(WrapperCreator creator) {
  var dartShadowed = InheritanceShadowed();
  var shadowed = creator.createInheritanceShadowed(dartShadowed);

  expect(hasProperty(shadowed, 'field'), false);
  expect(hasProperty(shadowed, 'finalField'), false);
  expect(hasProperty(shadowed, 'getSet'), false);

  expect(callMethod(shadowed, 'method', []), dartShadowed.method());
}

// Test that the arity is correct.
@JSExport()
class Arity {
  void onePositional(String arg1) {}
  void twoPositional(String arg1, String arg2) {}
  void oneOptional([String? arg1]) {}
  void twoOptional([String? arg1, String arg2 = '']) {}
  void onePositionalOneOptional(String arg1, [String? arg2]) {}
}

void testArity(WrapperCreator creator) {
  var arity = creator.createArity(Arity());

  callMethod(arity, 'onePositional', ['']);

  callMethod(arity, 'twoPositional', ['', '']);

  callMethod(arity, 'oneOptional', []);
  callMethod(arity, 'oneOptional', ['']);

  callMethod(arity, 'twoOptional', []);
  callMethod(arity, 'twoOptional', ['']);
  callMethod(arity, 'twoOptional', ['', '']);

  callMethod(arity, 'onePositionalOneOptional', ['']);
  callMethod(arity, 'onePositionalOneOptional', ['', '']);
}

// Test that the transformation occurs in other js_util calls.
void testNestedJsUtil(WrapperCreator creator) {
  setProperty(
      globalThis, 'export', creator.createExportAll(ExportAll.constructor()));
  expect(hasProperty(globalThis, 'export'), true);
  expect(hasProperty(getProperty(globalThis, 'export'), 'field'), true);
}

void test(WrapperCreator creator) {
  testExportAll(creator);
  testExportSome(creator);
  testForwarding(creator);
  testInheritance(creator);
  testOverrides(creator);
  testShadowed(creator);
  testArity(creator);
  testNestedJsUtil(creator);
}

// Test classes to test both `dart:js_interop`'s `createJSInteropWrapper` and
// `dart:js_util`'s `createDartExport`. Since both methods need the type
// parameter to be statically available, we have to use methods that statically
// declare what class they want wrapped.
abstract class WrapperCreator {
  Object createExportAll(ExportAll instance);
  Object createExportSome(ExportSome instance);
  Object createInheritance(Inheritance instance);
  Object createInheritanceShadowed(InheritanceShadowed instance);
  Object createOverrides(Overrides instance);
  Object createArity(Arity instance);
}

class UseCreateDartExport implements WrapperCreator {
  Object createExportAll(ExportAll instance) => createDartExport(instance);
  Object createExportSome(ExportSome instance) => createDartExport(instance);
  Object createInheritance(Inheritance instance) => createDartExport(instance);
  Object createInheritanceShadowed(InheritanceShadowed instance) =>
      createDartExport(instance);
  Object createOverrides(Overrides instance) => createDartExport(instance);
  Object createArity(Arity instance) => createDartExport(instance);
}

class UseCreateJSInteropWrapper implements WrapperCreator {
  JSObject createExportAll(ExportAll instance) =>
      createJSInteropWrapper(instance);
  JSObject createExportSome(ExportSome instance) =>
      createJSInteropWrapper(instance);
  JSObject createInheritance(Inheritance instance) =>
      createJSInteropWrapper(instance);
  JSObject createInheritanceShadowed(InheritanceShadowed instance) =>
      createJSInteropWrapper(instance);
  JSObject createOverrides(Overrides instance) =>
      createJSInteropWrapper(instance);
  JSObject createArity(Arity instance) => createJSInteropWrapper(instance);
}

void main() {
  test(UseCreateDartExport());
  test(UseCreateJSInteropWrapper());
}
