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
    defineReflectiveTests(ReplaceColonWithEqualsBulkTest);
    defineReflectiveTests(ReplaceColonWithEqualsTest);
  });
}

@reflectiveTest
class ReplaceColonWithEqualsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_equal_for_default_values;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f({int a: 1}) => null;

class C {
  void m({int a: 1, int b: 2}) => null;
}
''');
    await assertHasFix('''
void f({int a = 1}) => null;

class C {
  void m({int a = 1, int b = 2}) => null;
}
''');
  }
}

@reflectiveTest
class ReplaceColonWithEqualsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_COLON_WITH_EQUALS;

  @override
  String get lintCode => LintNames.prefer_equal_for_default_values;

  Future<void> test_method() async {
    await resolveTestCode('''
void f({int a: 1}) => null;
''');
    await assertHasFix('''
void f({int a = 1}) => null;
''');
  }

  Future<void> test_superParameter() async {
    await resolveTestCode('''
class C {
  C({int? i});
}
class D extends C {
  D({int? super.i: 1});
}
''');
    await assertHasFix('''
class C {
  C({int? i});
}
class D extends C {
  D({int? super.i = 1});
}
''');
  }
}
