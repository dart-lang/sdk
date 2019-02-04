// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDriverResolutionTest);
  });
}

@reflectiveTest
class EnumDriverResolutionTest extends DriverResolutionTest
    with EnumResolutionMixin {}

mixin EnumResolutionMixin implements ResolutionTest {
  test_error_conflictingStaticAndInstance_index() async {
    addTestFile(r'''
enum E {
  a, index
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_inference_listLiteral() async {
    addTestFile(r'''
enum E1 {a, b}
enum E2 {a, b}

var v = [E1.a, E2.b];
''');
    await resolveTestFile();
    assertNoTestErrors();

    var v = findElement.topVar('v');
    assertElementTypeString(v.type, 'List<Object>');
  }

  test_isConstantEvaluated() async {
    addTestFile(r'''
enum E {
  aaa, bbb
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    expect(findElement.field('aaa').isConstantEvaluated, isTrue);
    expect(findElement.field('bbb').isConstantEvaluated, isTrue);
    expect(findElement.field('values').isConstantEvaluated, isTrue);
  }
}
