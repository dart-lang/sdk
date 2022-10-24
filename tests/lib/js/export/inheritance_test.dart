// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that @staticInterop extension methods are collected from all extensions,
// including inheritance.

import 'package:expect/minitest.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class Extends {}

extension on Extends {
  external int extendsMethod(int val);
  external int extendsField;
  external final int extendsFinalField;
  external int get extendsGetSet;
  external set extendsGetSet(int val);
}

@JS()
@staticInterop
class Implements {}

extension on Implements {
  external int implementsMethod(int val);
  external int implementsField;
  external final int implementsFinalField;
  @JS('implementsGetSet')
  external int get implementsGetter;
  @JS('implementsGetSet')
  external set implementsSetter(int val);
}

@JS()
@staticInterop
class Inheritance extends Extends implements Implements {}

extension on Inheritance {
  external int method(int val);
  external int field;
  external final int finalField;
  external int get getSet;
  external set getSet(int val);
}

extension on Inheritance {
  external int method2(int val);
  external int field2;
  external final int finalField2;
  external int get getSet2;
  external set getSet2(int val);
}

@JSExport()
class ExtendsDart {
  int extendsMethod(int val) => val;
  int extendsField = 0;
  final int extendsFinalField = 0;
  int extendsGetSet = 0;
}

@JSExport()
class ImplementsMixin {
  int implementsMethod(int val) => val;
  int implementsField = 1;
  final int implementsFinalField = 1;
  int implementsGetSet = 1;
}

@JSExport()
class InheritanceDart extends ExtendsDart with ImplementsMixin {
  int method(int val) => val;
  int field = 2;
  final int finalField = 2;
  int getSet = 2;
  int method2(int val) => val;
  int field2 = 2;
  final int finalField2 = 2;
  int getSet2 = 2;
}

void main() {
  var dartMock = InheritanceDart();
  var jsMock = createStaticInteropMock<Inheritance, InheritanceDart>(dartMock);

  expect(jsMock.extendsMethod(0), 0);
  expect(jsMock.extendsField, 0);
  jsMock.extendsField = 1;
  expect(jsMock.extendsField, 1);
  expect(jsMock.extendsFinalField, 0);
  expect(jsMock.extendsGetSet, 0);
  // Dart mock uses a field for this getter and setter, so it should change.
  jsMock.extendsGetSet = 1;
  expect(jsMock.extendsGetSet, 1);

  expect(jsMock.implementsMethod(1), 1);
  expect(jsMock.implementsField, 1);
  jsMock.implementsField = 2;
  expect(jsMock.implementsField, 2);
  expect(jsMock.implementsFinalField, 1);
  expect(jsMock.implementsGetter, 1);
  jsMock.implementsSetter = 2;
  expect(jsMock.implementsGetter, 2);

  expect(jsMock.method(2), 2);
  expect(jsMock.field, 2);
  jsMock.field = 3;
  expect(jsMock.field, 3);
  expect(jsMock.finalField, 2);
  expect(jsMock.getSet, 2);
  jsMock.getSet = 3;
  expect(jsMock.getSet, 3);

  expect(jsMock.method2(2), 2);
  expect(jsMock.field2, 2);
  jsMock.field2 = 3;
  expect(jsMock.field2, 3);
  expect(jsMock.finalField2, 2);
  expect(jsMock.getSet2, 2);
  jsMock.getSet2 = 3;
  expect(jsMock.getSet2, 3);
}
