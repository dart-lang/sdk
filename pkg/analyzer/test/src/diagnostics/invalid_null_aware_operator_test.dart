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

  test_getter_class() async {
    await assertNoErrorsInCode('''
class C {
  static int x = 0;
}

f() {
  C?.x;
}
''');
  }

  test_getter_extension() async {
    await assertNoErrorsInCode('''
extension E on int {
  static int x = 0;
}

f() {
  E?.x;
}
''');
  }

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

  test_getter_mixin() async {
    await assertNoErrorsInCode('''
mixin M {
  static int x = 0;
}

f() {
  M?.x;
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

  /// Here we test that analysis does not crash while checking whether to
  /// report [StaticWarningCode.INVALID_NULL_AWARE_OPERATOR]. But we also
  /// report another error.
  test_getter_prefix() async {
    newFile('/test/lib/a.dart', content: r'''
int x = 0;
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

f() {
  p?.x;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 31, 1),
    ]);
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
  x?..[0];
}
''');
  }

  test_index_nonNullable() async {
    await assertErrorsInCode('''
f(List<int> x) {
  x?[0];
  x?..[0];
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 20, 2),
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 29, 3),
    ]);
  }

  test_index_nullable() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  x?[0];
  x?..[0];
}
''');
  }

  test_method_class() async {
    await assertNoErrorsInCode('''
class C {
  static void foo() {}
}

f() {
  C?.foo();
}
''');
  }

  test_method_extension() async {
    await assertNoErrorsInCode('''
extension E on int {
  static void foo() {}
}

f() {
  E?.foo();
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

  test_method_mixin() async {
    await assertNoErrorsInCode('''
mixin M {
  static void foo() {}
}

f() {
  M?.foo();
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

  test_setter_class() async {
    await assertNoErrorsInCode('''
class C {
  static int x = 0;
}

f() {
  C?.x = 0;
}
''');
  }

  test_setter_extension() async {
    await assertNoErrorsInCode('''
extension E on int {
  static int x = 0;
}

f() {
  E?.x = 0;
}
''');
  }

  test_setter_mixin() async {
    await assertNoErrorsInCode('''
mixin M {
  static int x = 0;
}

f() {
  M?.x = 0;
}
''');
  }

  /// Here we test that analysis does not crash while checking whether to
  /// report [StaticWarningCode.INVALID_NULL_AWARE_OPERATOR]. But we also
  /// report another error.
  test_setter_prefix() async {
    newFile('/test/lib/a.dart', content: r'''
int x = 0;
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

f() {
  p?.x = 0;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 31, 1),
    ]);
  }
}
