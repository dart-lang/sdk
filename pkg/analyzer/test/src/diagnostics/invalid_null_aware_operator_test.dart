// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNullAwareOperatorTest);
  });
}

@reflectiveTest
class InvalidNullAwareOperatorTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_getter_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  x?.isEven;
  x?..isEven;
}
''');
  }

  test_getter_nonNullable() async {
    await assertErrorsInCode('''
f(int x) {
  x?.isEven;
  x?..isEven;
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 14, 2),
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 27, 3),
    ]);
  }

  test_getter_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x?.isEven;
  x?..isEven;
}
''');
  }

  test_index_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = [0];
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  x?[0];
  x?.[0];
  x?..[0];
}
''');
  }

  test_index_nonNullable() async {
    await assertErrorsInCode('''
f(List<int> x) {
  x?[0];
  x?.[0];
  x?..[0];
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 20, 2),
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 29, 3),
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 39, 3),
    ]);
  }

  test_index_nullable() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  x?[0];
  x?.[0];
  x?..[0];
}
''');
  }

  test_method_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  x?.round();
  x?..round();
}
''');
  }

  test_method_nonNullable() async {
    await assertErrorsInCode('''
f(int x) {
  x?.round();
  x?..round();
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 14, 2),
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 28, 3),
    ]);
  }

  test_method_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x?.round();
  x?..round();
}
''');
  }

  test_nonNullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int> x) {
  [...x];
}
''');
  }

  test_nullableSpread_legacyType() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = <int>[];
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  [...?x];
}
''');
  }

  test_nullableSpread_nonNullableType() async {
    await assertErrorsInCode('''
f(List<int> x) {
  [...?x];
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 20, 4),
    ]);
  }

  test_nullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  [...?x];
}
''');
  }
}
