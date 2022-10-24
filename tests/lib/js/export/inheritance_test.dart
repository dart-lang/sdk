// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic inheritance test where @staticInterop class inherits extension methods
// which are then defined in the Dart class' inheritance chain, with some
// overrides.

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
  external int get getSet;
  external set getSet(int val);
}

@JS()
@staticInterop
class Implements {}

extension on Implements {
  @JS('_implementsMethod')
  external int implementsMethod(int val);
  @JS('_implementsField')
  external int implementsField;
  @JS('_implementsFinalField')
  external final int implementsFinalField;
  @JS('_implementsGetter')
  external int get implementsGetter;
  @JS('_implementsSetter')
  external set implementsSetter(int val);
}

@JS()
@staticInterop
class Inheritance extends Extends implements Implements {}

extension on Inheritance {
  external int method(int val);
  external int field;
  external final int finalField;
  // Overrides
  external int get getSet;
  external set getSet(int val);
}

class ExtendsDart {
  int extendsMethod(int val) => val;
  int extendsField = 0;
  final int extendsFinalField = 0;
  int getSet = 0;
}

class ImplementsMixin {
  int implementsMethod(int val) => val;
  int implementsField = 1;
  final int implementsFinalField = 1;
  int _implementsGetSet = 1;
  int get implementsGetter => _implementsGetSet;
  set implementsSetter(int val) => _implementsGetSet = val;
}

class InheritanceDart extends ExtendsDart with ImplementsMixin {
  int method(int val) => val;
  int field = 2;
  final int finalField = 2;
  @override
  int getSet = 2;
}

void main() {
  var dartMock = InheritanceDart();
  var jsMock = createStaticInteropMock<Inheritance, InheritanceDart>(dartMock);
  expect(jsMock.extendsMethod(0), 0);
  expect(jsMock.extendsField, 0);
  jsMock.extendsField = 1;
  expect(jsMock.extendsField, 1);
  expect(jsMock.extendsFinalField, 0);

  expect(jsMock.implementsMethod(1), 1);
  expect(jsMock.implementsField, 1);
  jsMock.implementsField = 2;
  expect(jsMock.implementsField, 2);
  expect(jsMock.implementsFinalField, 1);
  expect(jsMock.implementsGetter, 1);
  jsMock.implementsSetter = 2;
  // Dart mock uses a field for this getter and setter, so it should change.
  expect(jsMock.implementsGetter, 2);

  expect(jsMock.method(2), 2);
  expect(jsMock.field, 2);
  jsMock.field = 3;
  expect(jsMock.field, 3);
  expect(jsMock.finalField, 2);
  expect(jsMock.getSet, 2);
  jsMock.getSet = 3;
  expect(jsMock.getSet, 3);
}
