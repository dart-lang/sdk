// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Test that @staticInterop extension methods are collected from all extensions,
// including inheritance.

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class Extends {}

extension on Extends {
  external String extendsMethod(String val);
  external String extendsField;
  external final String extendsFinalField;
  external String get extendsGetSet;
  external set extendsGetSet(String val);
}

@JS()
@staticInterop
class Implements {}

extension on Implements {
  external String implementsMethod(String val);
  external String implementsField;
  external final String implementsFinalField;
  @JS('implementsGetSet')
  external String get implementsGetter;
  @JS('implementsGetSet')
  external set implementsSetter(String val);
}

@JS()
@staticInterop
class Inheritance extends Extends implements Implements {}

extension on Inheritance {
  external String method(String val);
  external String field;
  external final String finalField;
  external String get getSet;
  external set getSet(String val);
}

extension on Inheritance {
  external String method2(String val);
  external String field2;
  external final String finalField2;
  external String get getSet2;
  external set getSet2(String val);
}

@JSExport()
class ExtendsDart {
  String extendsMethod(String val) => val;
  String extendsField = 'extends';
  final String extendsFinalField = 'extends';
  String extendsGetSet = 'extends';
}

@JSExport()
class ImplementsMixin {
  String implementsMethod(String val) => val;
  String implementsField = 'implements';
  final String implementsFinalField = 'implements';
  String implementsGetSet = 'implements';
}

@JSExport()
class InheritanceDart extends ExtendsDart with ImplementsMixin {
  String method(String val) => val;
  String field = 'derived';
  final String finalField = 'derived';
  String getSet = 'derived';
  String method2(String val) => val;
  String field2 = 'derived';
  final String finalField2 = 'derived';
  String getSet2 = 'derived';
}

void main() {
  var dartMock = InheritanceDart();
  var jsMock = createStaticInteropMock<Inheritance, InheritanceDart>(dartMock);

  expect(jsMock.extendsMethod('extends'), 'extends');
  expect(jsMock.extendsField, 'extends');
  jsMock.extendsField = 'modified';
  expect(jsMock.extendsField, 'modified');
  expect(jsMock.extendsFinalField, 'extends');
  expect(jsMock.extendsGetSet, 'extends');
  // Dart mock uses a field for this getter and setter, so it should change.
  jsMock.extendsGetSet = 'modified';
  expect(jsMock.extendsGetSet, 'modified');

  expect(jsMock.implementsMethod('implements'), 'implements');
  expect(jsMock.implementsField, 'implements');
  jsMock.implementsField = 'modified';
  expect(jsMock.implementsField, 'modified');
  expect(jsMock.implementsFinalField, 'implements');
  expect(jsMock.implementsGetter, 'implements');
  jsMock.implementsSetter = 'modified';
  expect(jsMock.implementsGetter, 'modified');

  expect(jsMock.method('derived'), 'derived');
  expect(jsMock.field, 'derived');
  jsMock.field = 'modified';
  expect(jsMock.field, 'modified');
  expect(jsMock.finalField, 'derived');
  expect(jsMock.getSet, 'derived');
  jsMock.getSet = 'modified';
  expect(jsMock.getSet, 'modified');

  expect(jsMock.method2('derived'), 'derived');
  expect(jsMock.field2, 'derived');
  jsMock.field2 = 'modified';
  expect(jsMock.field2, 'modified');
  expect(jsMock.finalField2, 'derived');
  expect(jsMock.getSet2, 'derived');
  jsMock.getSet2 = 'modified';
  expect(jsMock.getSet2, 'modified');
}
