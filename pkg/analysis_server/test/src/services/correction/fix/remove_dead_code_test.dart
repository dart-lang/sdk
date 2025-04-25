// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDeadCodeClassicTest);
    defineReflectiveTests(RemoveDeadCodeSoundFlowAnalysisTest);
  });
}

@reflectiveTest
class RemoveDeadCodeClassicTest extends FixProcessorTest
    with RemoveDeadCodeClassicTestCases {
  @override
  String get testPackageLanguageVersion => '3.8.0';
}

/// Test cases for dead code removal that don't rely on the
/// `sound-flow-analysis` feature
mixin RemoveDeadCodeClassicTestCases on FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_DEAD_CODE;

  Future<void> test_and() async {
    await resolveTestCode('''
void f(bool b) => false && b;
''');
    await assertHasFix('''
void f(bool b) => false;
''');
  }

  Future<void> test_catch_afterCatchAll_catch() async {
    await resolveTestCode('''
void f() {
  try {
  } catch (e) {
    print('a');
  } catch (e) {
    print('b');
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } catch (e) {
    print('a');
  }
}
''');
  }

  Future<void> test_catch_afterCatchAll_on() async {
    await resolveTestCode('''
void f() {
  try {
  } on Object {
    print('a');
  } catch (e) {
    print('b');
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } on Object {
    print('a');
  }
}
''');
  }

  Future<void> test_catch_subtype() async {
    await resolveTestCode('''
class A {}
class B extends A {}
void f() {
  try {
  } on A {
    print('a');
  } on B {
    print('b');
  }
}
''');
    await assertHasFix('''
class A {}
class B extends A {}
void f() {
  try {
  } on A {
    print('a');
  }
}
''');
  }

  Future<void> test_condition_or() async {
    await resolveTestCode('''
void f(int p) {
  if (true || p > 5) {
    print(1);
  }
}
''');
    await assertHasFix('''
void f(int p) {
  if (true) {
    print(1);
  }
}
''');
  }

  Future<void> test_do_returnInBody() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
}
''');
  }

  Future<void> test_doWhile_atWhile() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
    print(c);
    return;
}
''');
  }

  Future<void> test_doWhile_atWhile_noBrackets() async {
    await resolveTestCode('''
void f(bool c) {
  do
    return;
  while (c);
}
''');
    await assertHasFix('''
void f(bool c) {
  return;
}
''');
  }

  Future<void> test_doWhile_break() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    if (c) {
     break;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_doWhile_break_doLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label:
  do {
    if (c) {
      break label;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_doWhile_break_inner() async {
    await resolveTestCode('''
void f(bool c) {
  do {
    while (c) {
      break;
    }
    return;
  } while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
    while (c) {
      break;
    }
    return;
  print('');
}
''', errorFilter: (error) => error.length == 12);
  }

  Future<void> test_doWhile_break_outerDoLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label:
  do {
    do {
      if (c) {
        break label;
      }
      return;
    } while (c);
    print('');
  } while (c);
  print('');
}
''');
    await assertHasFix('''
void f(bool c) {
  label:
  do {
      if (c) {
        break label;
      }
      return;
    print('');
  } while (c);
  print('');
}
''', errorFilter: (error) => error.length == 12);
  }

  Future<void> test_doWhile_break_outerLabel() async {
    await resolveTestCode('''
void f(bool c) {
  label: {
    do {
      if (c) {
       break label;
      }
      return;
    } while (c);
    print('');
  }
}
''');
    await assertHasFix('''
void f(bool c) {
  label: {
      if (c) {
       break label;
      }
      return;
    print('');
  }
}
''', errorFilter: (error) => error.length == 12);
  }

  Future<void> test_emptyStatement() async {
    await resolveTestCode('''
void f() {
  for (; false;);
}
''');
    await assertNoFix();
  }

  Future<void> test_for_returnInBody() async {
    await resolveTestCode('''
void f() {
  for (var i = 0; i < 2; i++) {
    print(i);
    return;
  }
}
''');
    await assertHasFix('''
void f() {
  for (var i = 0; i < 2; ) {
    print(i);
    return;
  }
}
''');
  }

  Future<void> test_forElement_throwInBody() async {
    await resolveTestCode('''
f() => [
  for (var i = 0; i < 2; i++) ...[
    i,
    throw ''
  ]
];
''');
    await assertHasFix('''
f() => [
  for (var i = 0; i < 2; ) ...[
    i,
    throw ''
  ]
];
''');
  }

  Future<void> test_forElementParts_updaters_multiple() async {
    await resolveTestCode('''
f() => [for (; false; 1, 2) 0];
''');
    await assertHasFix('''
f() => [for (; false; ) 0];
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forElementParts_updaters_multiple_comma() async {
    await resolveTestCode('''
f() => [for (; false; 1, 2,) 0];
''');
    await assertHasFix('''
f() => [for (; false; ) 0];
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forElementParts_updaters_throw() async {
    await resolveTestCode('''
f() => [for (;; 0, throw 1, 2) 0];
''');
    await assertHasFix('''
f() => [for (;; 0, throw 1) 0];
''');
  }

  Future<void> test_forElementParts_updaters_throw_comma() async {
    await resolveTestCode('''
f() => [for (;; 0, throw 1, 2,) 0];
''');
    await assertHasFix('''
f() => [for (;; 0, throw 1,) 0];
''');
  }

  Future<void> test_forElementParts_updaters_throw_multiple() async {
    await resolveTestCode('''
f() => [for (;; 0, throw 1, 2, 3) 0];
''');
    await assertHasFix('''
f() => [for (;; 0, throw 1) 0];
''');
  }

  Future<void> test_forElementParts_updaters_throw_multiple_comma() async {
    await resolveTestCode('''
f() => [for (;; 0, throw 1, 2, 3,) 0];
''');
    await assertHasFix('''
f() => [for (;; 0, throw 1,) 0];
''');
  }

  Future<void> test_forParts_updaters_multiple() async {
    await resolveTestCode('''
void f() {
  for (; false; 1, 2) {}
}
''');
    await assertHasFix('''
void f() {
  for (; false; ) {}
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forParts_updaters_multiple_comma() async {
    await resolveTestCode('''
void f() {
  for (; false; 1, 2,) {}
}
''');
    await assertHasFix('''
void f() {
  for (; false; ) {}
}
''', errorFilter: (error) => error.length == 4);
  }

  Future<void> test_forParts_updaters_throw() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_comma() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2,) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1,) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_multiple() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2, 3) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1) {}
}
''');
  }

  Future<void> test_forParts_updaters_throw_multiple_comma() async {
    await resolveTestCode('''
void f() {
  for (;; 0, throw 1, 2, 3,) {}
}
''');
    await assertHasFix('''
void f() {
  for (;; 0, throw 1,) {}
}
''');
  }

  Future<void> test_if_false_return() async {
    await resolveTestCode('''
void f() {
  if (false) return;
  print('');
}
''');
    // No fix. It's not safe to remove the `return;` statement, because then the
    // `if (false)` would cover the `print('');` statement.
    // TODO(paulberry): add the ability to recognize that `false` has no effect,
    // and thus it is safe to remove the entire `if` statement.
    await assertNoFix();
  }

  Future<void> test_statements_one() async {
    await resolveTestCode('''
int f() {
  print(0);
  return 42;
  print(1);
}
''');
    await assertHasFix('''
int f() {
  print(0);
  return 42;
}
''');
  }

  Future<void> test_statements_two() async {
    await resolveTestCode('''
int f() {
  print(0);
  return 42;
  print(1);
  print(2);
}
''');
    await assertHasFix('''
int f() {
  print(0);
  return 42;
}
''');
  }

  Future<void> test_switchCase_sharedStatements() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 5:
    case 3: break;
  }
}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 3: break;
  }
}
''');
  }

  Future<void> test_switchCase_sharedStatements_last() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 3:
    case 5:
      break;
  }
}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case 5:
    case 3:
    break;
  }
}
''');
  }

  Future<void> test_switchCase_uniqueStatements() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    case 5: print('');
    case 5: print('a');
    case 3: break;
  }
}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    case 5: print('');
    case 3: break;
  }
}
''');
  }

  Future<void> test_switchDefault_sharedStatements() async {
    await resolveTestCode('''
enum E { e1, e2 }
void f(E e) {
  switch(e) {
    case E.e1:
    case E.e2:
    default:
      break;
  }
}
''');
    await assertHasFix('''
enum E { e1, e2 }
void f(E e) {
  switch(e) {
    case E.e1:
    case E.e2:
    break;
  }
}
''');
  }

  Future<void> test_switchDefault_uniqueStatements() async {
    await resolveTestCode('''
enum E { e1, e2 }
void f(E e) {
  switch(e) {
    case E.e1: print('e1');
    case E.e2: print('e2');
    default: print('e3');
  }
}
''');
    await assertHasFix('''
enum E { e1, e2 }
void f(E e) {
  switch(e) {
    case E.e1: print('e1');
    case E.e2: print('e2');
    }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50950')
  Future<void> test_switchExpression() async {
    await resolveTestCode('''
void f() {
  var m = 5;
  switch(m) {
    5 => '',
    5 => 'a',
    3 => 'b'
}

}
''');
    await assertHasFix('''
void f() {
  var m = 5;
  switch(m) {
    5 => '',
    3 => 'b'
}

  }
}
''');
  }
}

@reflectiveTest
class RemoveDeadCodeSoundFlowAnalysisTest extends FixProcessorTest
    with RemoveDeadCodeClassicTestCases {
  @override
  List<String> get experiments => [...super.experiments, 'sound-flow-analysis'];

  Future<void> test_ifNull() async {
    await resolveTestCode('''
void f(int i, int j) => i ?? j;
''');
    await assertHasFix('''
void f(int i, int j) => i;
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  /// Error filter ignoring warnings that frequently occur in conjunction with
  /// code that is dead due to sound flow analysis.
  bool _ignoreNullSafetyWarnings(AnalysisError error) =>
      error.errorCode.name != 'DEAD_NULL_AWARE_EXPRESSION';
}
