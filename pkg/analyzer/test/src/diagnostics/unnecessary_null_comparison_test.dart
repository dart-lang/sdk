// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import '../dart/resolution/with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullComparisonFalseTest);
    defineReflectiveTests(UnnecessaryNullComparisonTrueTest);
  });
}

@reflectiveTest
class UnnecessaryNullComparisonFalseTest extends DriverResolutionTest
    with WithNullSafetyMixin {
  test_equal_intLiteral() async {
    await assertNoErrorsInCode('''
f(int a, int? b) {
  a == 0;
  0 == a;
  b == 0;
  0 == b;
}
''');
  }

  test_equal_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var a = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  a == null;
  null == a;
}
''');
  }

  test_equal_legacyLibrary() async {
    await assertNoErrorsInCode('''
// @dart = 2.5
f(int a) {
  a == null;
  null == a;
}
''');
  }

  test_equal_notNullable() async {
    await assertErrorsInCode('''
f(int a) {
  a == null;
  null == a;
}
''', [
      error(HintCode.UNNECESSARY_NULL_COMPARISON_FALSE, 15, 7),
      error(HintCode.UNNECESSARY_NULL_COMPARISON_FALSE, 26, 7),
    ]);
  }

  test_equal_nullable() async {
    await assertNoErrorsInCode('''
f(int? a) {
  a == null;
  null == a;
}
''');
  }
}

@reflectiveTest
class UnnecessaryNullComparisonTrueTest extends DriverResolutionTest
    with WithNullSafetyMixin {
  test_notEqual_intLiteral() async {
    await assertNoErrorsInCode('''
f(int a, int? b) {
  a != 0;
  0 != a;
  b != 0;
  0 != b;
}
''');
  }

  test_notEqual_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var a = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  a != null;
  null != a;
}
''');
  }

  test_notEqual_legacyLibrary() async {
    await assertNoErrorsInCode('''
// @dart = 2.5
f(int a) {
  a != null;
  null != a;
}
''');
  }

  test_notEqual_notNullable() async {
    await assertErrorsInCode('''
f(int a) {
  a != null;
  null != a;
}
''', [
      error(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE, 15, 7),
      error(HintCode.UNNECESSARY_NULL_COMPARISON_TRUE, 26, 7),
    ]);
  }

  test_notEqual_nullable() async {
    await assertNoErrorsInCode('''
f(int? a) {
  a != null;
  null != a;
}
''');
  }
}
