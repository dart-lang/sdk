// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that using `createStaticInteropMock` with pkg:mockito works as expected.

import 'package:expect/minitest.dart';
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
  external int? method(int? val);
  external int? field;
  external final int? finalField;
  external int? get getSet;
  external set getSet(int? val);
}

class Dart {
  int? method(int? val) => throw '';
  int? field = throw '';
  final int? finalField = throw '';
  int? get getSet => throw '';
  set getSet(int? val) => throw '';
}

// Have the mock class implement the class interface you defined to mock the
// @staticInterop interface.
class DartMock extends Mock implements Dart {}

void main() {
  // Write expectations on the Dart Mock object, not the JS mock object.
  var dartMock = DartMock();
  var jsMock = createStaticInteropMock<StaticInterop, DartMock>(dartMock);
  when(dartMock.method(0)).thenReturn(1);
  when(dartMock.field).thenReturn(1);
  when(dartMock.finalField).thenReturn(1);
  when(dartMock.getSet).thenReturn(1);
  expect(jsMock.method(0), 1);
  expect(jsMock.field, 1);
  expect(jsMock.finalField, 1);
  expect(jsMock.getSet, 1);
  jsMock.getSet = 1;
  verify(dartMock.getSet = 1);
}
