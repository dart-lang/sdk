// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
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

  Future<void> test_default_declaredType() async {
    await resolveTestCode('''
Set s = Set();
''');
    await assertHasFix('''
Set s = {};
''');
  }

  Future<void> test_default_minimal() async {
    await resolveTestCode('''
var s = Set();
''');
    await assertHasFix('''
var s = <dynamic>{};
''');
  }

  Future<void> test_default_newKeyword() async {
    await resolveTestCode('''
var s = new Set();
''');
    await assertHasFix('''
var s = <dynamic>{};
''');
  }

  Future<void> test_default_typeArg() async {
    await resolveTestCode('''
var s = Set<int>();
''');
    await assertHasFix('''
var s = <int>{};
''');
  }

  @failingTest
  Future<void> test_default_typeArg_linkedHashSet() async {
    // LinkedHashSet isn't converted even though the lint reports that case.
    await resolveTestCode('''
import 'dart:collection';

var s = LinkedHashSet<int>();
''');
    await assertHasFix('''
import 'dart:collection';

var s = <int>{};
''');
  }

  Future<void> test_from_empty() async {
    await resolveTestCode('''
var s = Set.from([]);
''');
    await assertHasFix('''
var s = <dynamic>{};
''');
  }

  Future<void> test_from_inferred() async {
    await resolveTestCode('''
void f(Set<int> s) {}
var s = f(Set.from([]));
''');
    await assertHasFix('''
void f(Set<int> s) {}
var s = f({});
''');
  }

  Future<void> test_from_newKeyword() async {
    await resolveTestCode('''
var s = new Set.from([2, 3]);
''');
    await assertHasFix('''
var s = {2, 3};
''');
  }

  Future<void> test_from_noKeyword_declaredType() async {
    await resolveTestCode('''
Set s = Set.from([2, 3]);
''');
    await assertHasFix('''
Set s = {2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onConstructor() async {
    await resolveTestCode('''
var s = Set<int>.from([2, 3]);
''');
    await assertHasFix('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onConstructorAndLiteral() async {
    await resolveTestCode('''
var s = Set<int>.from(<num>[2, 3]);
''');
    await assertHasFix('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onLiteral() async {
    await resolveTestCode('''
var s = Set.from(<int>[2, 3]);
''');
    await assertHasFix('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_nonEmpty() async {
    await resolveTestCode('''
var s = Set.from([2, 3]);
''');
    await assertHasFix('''
var s = {2, 3};
''');
  }

  Future<void> test_from_trailingComma() async {
    await resolveTestCode('''
var s = Set.from([2, 3,]);
''');
    await assertHasFix('''
var s = {2, 3,};
''');
  }

  Future<void> test_toSet_empty() async {
    await resolveTestCode('''
var s = [].toSet();
''');
    await assertHasFix('''
var s = <dynamic>{};
''');
  }

  Future<void> test_toSet_empty_typeArg() async {
    await resolveTestCode('''
var s = <int>[].toSet();
''');
    await assertHasFix('''
var s = <int>{};
''');
  }

  Future<void> test_toSet_nonEmpty() async {
    await resolveTestCode('''
var s = [2, 3].toSet();
''');
    await assertHasFix('''
var s = {2, 3};
''');
  }

  Future<void> test_toSet_nonEmpty_typeArg() async {
    await resolveTestCode('''
var s = <int>[2, 3].toSet();
''');
    await assertHasFix('''
var s = <int>{2, 3};
''');
  }
}
