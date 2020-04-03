// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableTest);
  });
}

@reflectiveTest
class LocalVariableTest extends DriverResolutionTest {
  void assertPromotedBound(DartType type, Matcher promotedBound) {
    if (type is TypeParameterTypeImpl) {
      expect(type.promotedBound, promotedBound);
    }
  }

  test_demoteTypeParameterType() async {
    await assertNoErrorsInCode('''
void f<T>(T a, T b) {
  if (a is String) {
    var o = a;
    o = b;
    o; // ref
  }
}
''');

    var type = findNode.simple('o; // ref').staticType;
    assertType(type, 'T');
    assertPromotedBound(type, isNull);
  }
}
