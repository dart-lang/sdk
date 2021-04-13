// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareTest);
  });
}

@reflectiveTest
class ConvertToNullAwareTest extends BulkFixProcessorTest {
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
