// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopTypeInferenceDriverResolutionTest);
  });
}

@reflectiveTest
class TopTypeInferenceDriverResolutionTest extends DriverResolutionTest
    with TopTypeInstanceMixin {}

mixin TopTypeInstanceMixin implements ResolutionTest {
  test_referenceInstanceVariable_withDeclaredType() async {
    addTestFile(r'''
class A {
  final int a = b + 1;
}
final b = new A().a;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElementTypeString(findElement.field('a').type, 'int');
    assertElementTypeString(findElement.topVar('b').type, 'int');
  }

  test_referenceInstanceVariable_withoutDeclaredType() async {
    addTestFile(r'''
class A {
  final a = b + 1;
}
final b = new A().a;
''');
    await resolveTestFile();
    assertTestErrors([StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);

    assertElementTypeDynamic(findElement.field('a').type);
    assertElementTypeDynamic(findElement.topVar('b').type);
  }
}
