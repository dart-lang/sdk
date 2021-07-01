// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareBulkTest);
    defineReflectiveTests(ConvertToNullAwareTest);
  });
}

@reflectiveTest
class ConvertToNullAwareBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_null_aware_operators;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  int m(int p) => p;
}
int f(A x, A y) => x == null ? null : x.m(y == null ? null : y.m(0));
''');
    await assertHasFix('''
class A {
  int m(int p) => p;
}
int f(A x, A y) => x?.m(y?.m(0));
''');
  }
}

@reflectiveTest
class ConvertToNullAwareTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_NULL_AWARE;

  @override
  String get lintCode => LintNames.prefer_null_aware_operators;

  /// More coverage in the `convert_to_null_aware_test.dart` assist test.
  Future<void> test_equal_nullOnLeft() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int? f(A? a) => null == a ? null : a.m();
''');
    await assertHasFix('''
abstract class A {
  int m();
}
int? f(A? a) => a?.m();
''');
  }
}
