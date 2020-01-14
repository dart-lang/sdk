// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSetLiteralTest);
  });
}

@reflectiveTest
class ConvertToSetLiteralTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_SET_LITERAL;

  @override
  String get lintCode => LintNames.prefer_collection_literals;

  test_default_declaredType() async {
    await resolveTestUnit('''
Set s = /*LINT*/Set();
''');
    await assertHasFix('''
Set s = /*LINT*/{};
''');
  }

  test_default_minimal() async {
    await resolveTestUnit('''
var s = /*LINT*/Set();
''');
    await assertHasFix('''
var s = /*LINT*/<dynamic>{};
''');
  }

  test_default_newKeyword() async {
    await resolveTestUnit('''
var s = /*LINT*/new Set();
''');
    await assertHasFix('''
var s = /*LINT*/<dynamic>{};
''');
  }

  test_default_typeArg() async {
    await resolveTestUnit('''
var s = /*LINT*/Set<int>();
''');
    await assertHasFix('''
var s = /*LINT*/<int>{};
''');
  }

  test_from_empty() async {
    await resolveTestUnit('''
var s = /*LINT*/Set.from([]);
''');
    await assertHasFix('''
var s = /*LINT*/<dynamic>{};
''');
  }

  test_from_newKeyword() async {
    await resolveTestUnit('''
var s = /*LINT*/new Set.from([2, 3]);
''');
    await assertHasFix('''
var s = /*LINT*/{2, 3};
''');
  }

  test_from_noKeyword_declaredType() async {
    await resolveTestUnit('''
Set s = /*LINT*/Set.from([2, 3]);
''');
    await assertHasFix('''
Set s = /*LINT*/{2, 3};
''');
  }

  test_from_noKeyword_typeArg_onConstructor() async {
    await resolveTestUnit('''
var s = /*LINT*/Set<int>.from([2, 3]);
''');
    await assertHasFix('''
var s = /*LINT*/<int>{2, 3};
''');
  }

  test_from_noKeyword_typeArg_onConstructorAndLiteral() async {
    await resolveTestUnit('''
var s = /*LINT*/Set<int>.from(<num>[2, 3]);
''');
    await assertHasFix('''
var s = /*LINT*/<int>{2, 3};
''');
  }

  test_from_noKeyword_typeArg_onLiteral() async {
    await resolveTestUnit('''
var s = /*LINT*/Set.from(<int>[2, 3]);
''');
    await assertHasFix('''
var s = /*LINT*/<int>{2, 3};
''');
  }

  test_from_nonEmpty() async {
    await resolveTestUnit('''
var s = /*LINT*/Set.from([2, 3]);
''');
    await assertHasFix('''
var s = /*LINT*/{2, 3};
''');
  }

  test_from_notALiteral() async {
    await resolveTestUnit('''
var l = [1];
Set s = /*LINT*/new Set.from(l);
''');
    await assertNoFix();
  }

  test_from_trailingComma() async {
    await resolveTestUnit('''
var s = /*LINT*/Set.from([2, 3,]);
''');
    await assertHasFix('''
var s = /*LINT*/{2, 3,};
''');
  }

  test_toSet_empty() async {
    await resolveTestUnit('''
var s = /*LINT*/[].toSet();
''');
    await assertHasFix('''
var s = /*LINT*/<dynamic>{};
''');
  }

  test_toSet_empty_typeArg() async {
    await resolveTestUnit('''
var s = /*LINT*/<int>[].toSet();
''');
    await assertHasFix('''
var s = /*LINT*/<int>{};
''');
  }

  test_toSet_nonEmpty() async {
    await resolveTestUnit('''
var s = /*LINT*/[2, 3].toSet();
''');
    await assertHasFix('''
var s = /*LINT*/{2, 3};
''');
  }

  test_toSet_nonEmpty_typeArg() async {
    await resolveTestUnit('''
var s = /*LINT*/<int>[2, 3].toSet();
''');
    await assertHasFix('''
var s = /*LINT*/<int>{2, 3};
''');
  }

  test_toSet_notALiteral() async {
    await resolveTestUnit('''
var l = [];
var s = /*LINT*/l.toSet();
''');
    await assertNoFix();
  }
}
