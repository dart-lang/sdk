// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferGenericFunctionTypeAliasesTest);
  });
}

@reflectiveTest
class PreferGenericFunctionTypeAliasesTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_generic_function_type_aliases;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
typedef String F(int x);
typedef F2<P, R>(P x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
typedef F2<P, R> = Function(P x);
''');
  }
}
