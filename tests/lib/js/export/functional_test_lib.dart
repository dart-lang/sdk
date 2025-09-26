// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

// Test exporting all vs. only some members.
// Also test using a non-empty `@JSExport` annotation on a class, which should
// be a warning but should not prevent code generation.
@JSExport('A')
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
  expect(all.has('constructor'), false);
  expect(all.has('factory'), false);
  expect(all.has('field'), true);
  expect(all.has('finalField'), true);
  expect(all.has('_getSetField'), true);
  expect(all.has('getSet'), true);
  expect(all.has('method'), true);
  expect(all.has('staticField'), false);
  expect(all.has('staticMethod'), false);
  expect(all.has('extensionMethod'), false);
  expect(all.has('extensionStaticField'), false);
  expect(all.has('extensionStaticMethod'), false);
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
  expect(some.has('constructor'), false);
  expect(some.has('factory'), false);

  expect(some.has('field'), true);
  expect(some.has('finalField'), true);
  expect(some.has('getSet'), true);
  expect(some.has('method'), true);

  expect(some.has('nonExportField'), false);
  expect(some.has('nonExportFinalField'), false);
  expect(some.has('nonExportGetSet'), false);
  expect(some.has('nonExportMethod'), false);
}

// Test that the properties are forwarded correctly in the object literal.
void testForwarding(WrapperCreator creator) {
  var dartInstance = ExportAll.constructor();
  var all = creator.createExportAll(dartInstance);

  expect(all['field'], dartInstance.field.toJS);
  all['field'] = 'modified'.toJS;
  expect(dartInstance.field, 'modified');

  expect(all['finalField'], dartInstance.finalField.toJS);

  expect(all['getSet'], dartInstance.getSet.toJS);
  all['getSet'] = 'modified'.toJS;
  expect(dartInstance.getSet, 'modified');

  expect(all.callMethod('method'.toJS), dartInstance.method().toJS);
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

  expect(inheritance['field'], dartInheritance.field.toJS);
  inheritance['field'] = 'modified'.toJS;
  expect(dartInheritance.field, 'modified');

  expect(inheritance['finalField'], dartInheritance.finalField.toJS);

  expect(inheritance['getSet'], dartInheritance.getSet.toJS);
  inheritance['getSet'] = 'superclassSetter'.toJS;

  expect(inheritance.callMethod('method'.toJS), dartInheritance.method().toJS);
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

  expect(overrides['field'], dartOverrides.field.toJS);
  overrides['field'] = 'modified'.toJS;
  expect(dartOverrides.field, 'modified');

  expect(overrides['finalField'], dartOverrides.finalField.toJS);

  expect(overrides['getSet'], dartOverrides.getSet.toJS);
  overrides['getSet'] = 'derivedSetter'.toJS;

  expect(overrides.callMethod('method'.toJS), dartOverrides.method().toJS);
  expect(
    overrides.callMethod('nonOverriddenMethod'.toJS),
    dartOverrides.nonOverriddenMethod().toJS,
  );
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

  expect(shadowed.has('field'), false);
  expect(shadowed.has('finalField'), false);
  expect(shadowed.has('getSet'), false);

  expect(shadowed.callMethod('method'.toJS), dartShadowed.method().toJS);
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

  arity.callMethod('onePositional'.toJS, ''.toJS);

  arity.callMethod('twoPositional'.toJS, ''.toJS, ''.toJS);

  arity.callMethod('oneOptional'.toJS);
  arity.callMethod('oneOptional'.toJS, ''.toJS);

  arity.callMethod('twoOptional'.toJS);
  arity.callMethod('twoOptional'.toJS, ''.toJS);
  arity.callMethod('twoOptional'.toJS, ''.toJS, ''.toJS);

  arity.callMethod('onePositionalOneOptional'.toJS, ''.toJS);
  arity.callMethod('onePositionalOneOptional'.toJS, ''.toJS, ''.toJS);
}

// Test that the transformation occurs in other js_util calls.
void testNestedJsUtil(WrapperCreator creator) {
  globalContext['export'] = creator.createExportAll(ExportAll.constructor());
  expect(globalContext.has('export'), true);
  expect((globalContext['export'] as JSObject).has('field'), true);
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
  JSObject createExportAll(ExportAll instance);
  JSObject createExportSome(ExportSome instance);
  JSObject createInheritance(Inheritance instance);
  JSObject createInheritanceShadowed(InheritanceShadowed instance);
  JSObject createOverrides(Overrides instance);
  JSObject createArity(Arity instance);
}
