// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that using `createStaticInteropMock` with pkg:mockito works as expected.

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:mockito/mockito.dart';

@JS()
@staticInterop
class StaticInterop {}

extension on StaticInterop {
  // We use nullable types here as mockito requires some additional complexity
  // or code generation to safely mock non-nullables.
  // https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
  external String? method(String? val);
  external String? field;
  external final String? finalField;
  external String? get getSet;
  external set getSet(String? val);
}

@JSExport()
class Dart {
  String? method(String? val) => throw '';
  String? field = throw '';
  final String? finalField = throw '';
  String? get getSet => throw '';
  set getSet(String? val) => throw '';
}

// Have the mock class implement the class interface you defined to mock the
// @staticInterop interface.
@JSExport()
class DartMock extends Mock implements Dart {}

void main() {
  // Write expectations on the Dart Mock object, not the JS mock object.
  var dartMock = DartMock();
  var jsMock = createStaticInteropMock<StaticInterop, DartMock>(dartMock);
  when(dartMock.method('value')).thenReturn('mockValue');
  when(dartMock.field).thenReturn('mockValue');
  when(dartMock.finalField).thenReturn('mockValue');
  when(dartMock.getSet).thenReturn('mockValue');
  expect(jsMock.method('value'), 'mockValue');
  expect(jsMock.field, 'mockValue');
  expect(jsMock.finalField, 'mockValue');
  expect(jsMock.getSet, 'mockValue');
  jsMock.getSet = 'mockValue';
  verify(dartMock.getSet = 'mockValue');
}
