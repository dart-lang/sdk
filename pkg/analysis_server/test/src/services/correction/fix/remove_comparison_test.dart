// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveComparisonTest);
    defineReflectiveTests(RemoveTypeCheckTest);
    defineReflectiveTests(RemoveTypeCheckBulkTest);
    defineReflectiveTests(RemoveNullCheckComparisonTest);
    defineReflectiveTests(RemoveNullCheckComparisonBulkTest);
  });
}

@reflectiveTest
class RemoveComparisonTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_COMPARISON;

  Future<void> test_assertInitializer_first() async {
    await resolveTestCode('''
class C {
  String t;
  C(String s) : assert(s != null), t = s;
}
''');
    await assertHasFix('''
class C {
  String t;
  C(String s) : t = s;
}
''');
  }

  Future<void> test_assertInitializer_last() async {
    await resolveTestCode('''
class C {
  String t;
  C(String s) : t = s, assert(s != null);
}
''');
    await assertHasFix('''
class C {
  String t;
  C(String s) : t = s;
}
''');
  }

  Future<void> test_assertInitializer_middle() async {
    await resolveTestCode('''
class C {
  String t;
  String u;
  C(String s) : t = s, assert(s != null), u = s;
}
''');
    await assertHasFix('''
class C {
  String t;
  String u;
  C(String s) : t = s, u = s;
}
''');
  }

  Future<void> test_assertInitializer_only() async {
    await resolveTestCode('''
class C {
  C(String s) : assert(s != null);
}
''');
    await assertHasFix('''
class C {
  C(String s);
}
''');
  }

  Future<void> test_assertStatement() async {
    await resolveTestCode('''
void f(String s) {
  assert(s != null);
  print(s);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s);
}
''');
  }

  Future<void> test_binaryExpression_and_left() async {
    await resolveTestCode('''
void f(String s) {
  print(s != null && s.isNotEmpty);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isNotEmpty);
}
''');
  }

  Future<void> test_binaryExpression_and_right() async {
    await resolveTestCode('''
void f(String s) {
  print(s.isNotEmpty && s != null);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isNotEmpty);
}
''');
  }

  Future<void> test_binaryExpression_or_left() async {
    await resolveTestCode('''
void f(String s) {
  print(s == null || s.isEmpty);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isEmpty);
}
''');
  }

  Future<void> test_binaryExpression_or_right() async {
    await resolveTestCode('''
void f(String s) {
  print(s.isEmpty || s == null);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isEmpty);
}
''');
  }

  Future<void> test_ifElement_alwaysFalse_hasElse() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    if (x == null) 1 else -1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    -1,
    2,
  ];
}
''');
  }

  Future<void> test_ifElement_alwaysFalse_hasElse_withComments() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    // C1
    if (x == null)
      // C2
      1
    else
      // C3
      -1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    // C1
    // C3
    -1,
    2,
  ];
}
''');
  }

  Future<void> test_ifElement_alwaysFalse_noElse_insideList() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    if (x == null) 1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    2,
  ];
}
''');
  }

  Future<void>
      test_ifElement_alwaysFalse_noElse_insideList_withComments() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    // C1
    if (x == null)
      // C2
      1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    2,
  ];
}
''');
  }

  Future<void> test_ifElement_alwaysFalse_noElse_insideSet() async {
    await resolveTestCode('''
Object f(int x) {
  return {
    0,
    if (x == null) 1,
    2,
  };
}
''');
    await assertHasFix('''
Object f(int x) {
  return {
    0,
    2,
  };
}
''');
  }

  Future<void> test_ifElement_alwaysTrue() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    if (x != null)
      1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    1,
    2,
  ];
}
''');
  }

  Future<void> test_ifElement_alwaysTrue_hasElse() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    if (x != null) 1 else -1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    1,
    2,
  ];
}
''');
  }

  Future<void> test_ifElement_alwaysTrue_withComments() async {
    await resolveTestCode('''
void f(int x) {
  [
    0,
    // C1
    if (x != null)
      // C2
      1,
    2,
  ];
}
''');
    await assertHasFix('''
void f(int x) {
  [
    0,
    // C1
    // C2
    1,
    2,
  ];
}
''');
  }

  Future<void> test_ifStatement_alwaysFalse_hasElse_block() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x == null) {
    1;
  } else {
    2;
  }
  3;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  2;
  3;
}
''');
  }

  Future<void> test_ifStatement_alwaysFalse_hasElse_block_empty() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x == null) {
    1;
  } else {}
  2;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  2;
}
''');
  }

  Future<void> test_ifStatement_alwaysFalse_hasElse_statement() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x == null) {
    1;
  } else
    2;
  3;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  2;
  3;
}
''');
  }

  Future<void> test_ifStatement_alwaysFalse_noElse() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x == null) {
    1;
  }
  2;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  2;
}
''');
  }

  Future<void> test_ifStatement_alwaysTrue_hasElse_block() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x != null) {
    1;
  } else {
    2;
  }
  3;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  1;
  3;
}
''');
  }

  Future<void> test_ifStatement_alwaysTrue_noElse() async {
    await resolveTestCode('''
void f(int x) {
  0;
  if (x != null) {
    1;
  }
  2;
}
''');
    await assertHasFix('''
void f(int x) {
  0;
  1;
  2;
}
''');
  }

  Future<void> test_ifStatement_thenBlock() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null) {
    print(s);
  }
}
''');
    await assertHasFix('''
void f(String s) {
  print(s);
}
''');
  }

  Future<void> test_ifStatement_thenBlock_empty() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null) {
  }
}
''');
    await assertHasFix('''
void f(String s) {
}
''');
  }

  Future<void> test_ifStatement_thenBlock_empty_justComment() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null) {
    // comment 1
    // comment 2
  }
}
''');
    await assertHasFix('''
void f(String s) {
  // comment 1
  // comment 2
}
''');
  }

  Future<void> test_ifStatement_thenBlock_empty_sameLine() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null) {}
}
''');
    await assertHasFix('''
void f(String s) {
}
''');
  }

  Future<void> test_ifStatement_thenBlock_withComment() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null) {
    // leading 1
    // leading 2
    print(s);
    // trailing 1
    // trailing 2
  }
}
''');
    await assertHasFix('''
void f(String s) {
  // leading 1
  // leading 2
  print(s);
  // trailing 1
  // trailing 2
}
''');
  }

  Future<void> test_ifStatement_thenStatement() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null)
    print(s);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s);
}
''');
  }

  Future<void> test_ifStatement_thenStatement_withComment() async {
    await resolveTestCode('''
void f(String s) {
  if (s != null)
    /// comment 1
    /// comment 2
    print(s);
    /// comment 1
    /// comment 2
}
''');
    await assertHasFix('''
void f(String s) {
  /// comment 1
  /// comment 2
  print(s);
    /// comment 1
    /// comment 2
}
''');
  }

  Future<void> test_unnecessaryNanComparison_false() async {
    await resolveTestCode('''
void f(double d) {
  if (d == double.nan || d == 0) {
    print('');
  }
}
''');
    await assertHasFix('''
void f(double d) {
  if (d == 0) {
    print('');
  }
}
''');
  }

  Future<void> test_unnecessaryNanComparison_true() async {
    await resolveTestCode('''
void f(double d) {
  if (d != double.nan) {
    print('');
  }
}
''');
    await assertHasFix('''
void f(double d) {
  print('');
}
''');
  }
}

@reflectiveTest
class RemoveNullCheckComparisonBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_null_checks_in_equality_operators;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other != null &&
          other is Person &&
          name == other.name;
}

class Person2 {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other != null &&
          other is Person &&
          name == other.name;
}
''');
    await assertHasFix('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other is Person &&
          name == other.name;
}

class Person2 {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other is Person &&
          name == other.name;
}
''');
  }

  @FailingTest(reason: 'Only the first comparison is removed')
  Future<void> test_singleFile_overlapping() async {
    await resolveTestCode('''
class Person {
  final String name = '';

  @override
  operator ==(other) =>
          other != null &&
          other != null &&
          other is Person &&
          name == other.name;
}
''');
    await assertHasFix('''
class Person {
  final String name = '';

  @override
  operator ==(other) =>
          other is Person &&
          name == other.name;
}
''');
  }
}

@reflectiveTest
class RemoveNullCheckComparisonTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_COMPARISON;

  @override
  String get lintCode => LintNames.avoid_null_checks_in_equality_operators;

  Future<void> test_expressionBody() async {
    await resolveTestCode('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other != null &&
          other is Person &&
          name == other.name;
}
''');
    await assertHasFix('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) =>
          other is Person &&
          name == other.name;
}
''');
  }

  Future<void> test_functionBody() async {
    await resolveTestCode('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) {
    return other != null &&
          other is Person &&
          name == other.name;
  }
}
''');
    await assertHasFix('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) {
    return other is Person &&
          name == other.name;
  }
}
''');
  }

  Future<void> test_ifNullAssignmentStatement() async {
    await resolveTestCode('''
class Person {
  final String name = '';

  @override
  operator ==(Object? other) {
    if (other is! Person) return false;
    other ??= Person();
    return other.name == name;
  }
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class RemoveTypeCheckBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(int a, int b) {
  if (a is! num || b == 0) {
    print('');
  }
}
void g(int a, int b) {
  if (b == 0 && a is num) {
    print('');
  }
}
''');
    await assertHasFix('''
void f(int a, int b) {
  if (b == 0) {
    print('');
  }
}
void g(int a, int b) {
  if (b == 0) {
    print('');
  }
}
''');
  }
}

@reflectiveTest
class RemoveTypeCheckTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_TYPE_CHECK;

  Future<void> test_unnecessaryTypeCheck_false() async {
    await resolveTestCode('''
void f(int a, int b) {
  if (a is! num || b == 0) {
    print('');
  }
}
''');
    await assertHasFix('''
void f(int a, int b) {
  if (b == 0) {
    print('');
  }
}
''');
  }

  Future<void> test_unnecessaryTypeCheck_true() async {
    await resolveTestCode('''
void f(int a, int b) {
  if (b == 0 && a is num) {
    print('');
  }
}
''');
    await assertHasFix('''
void f(int a, int b) {
  if (b == 0) {
    print('');
  }
}
''');
  }
}
