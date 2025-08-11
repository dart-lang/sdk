// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
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

  Future<void> test_conditionalExpression_falseCondition() async {
    await resolveTestCode('''
void f(int i, int j) => false ? i : j;
''');
    await assertHasFix('''
void f(int i, int j) => j;
''');
  }

  Future<void>
  test_conditionalExpression_falseCondition_cascadeException() async {
    // It's not safe to transform something like
    // `a ? b : throw c..cascadeSection` into `throw c..cascadeSection`, because
    // the former parses as `(a ? b : throw c)..cascadeSection`, and the latter
    // parses as `throw (c..cascadeSection)`.
    var code = '''
void f(int i, int j) => false ? i : throw j..abs();
''';
    await resolveTestCode(code);
    await assertNoFix(
      errorFilter: (error) => error.offset == code.indexOf('i :'),
    );
  }

  Future<void> test_conditionalExpression_trueCondition() async {
    await resolveTestCode('''
void f(int i, int j) => true ? i : j;
''');
    await assertHasFix('''
void f(int i, int j) => i;
''');
  }

  Future<void>
  test_conditionalExpression_trueCondition_cascadeException() async {
    // It's not safe to transform something like
    // `a ? throw b : c..cascadeSection` into `throw b..cascadeSection`, because
    // the former parses as `(a ? throw b : c)..cascadeSection`, and the latter
    // parses as `throw (b..cascadeSection)`.
    var code = '''
void f(int i, int j) => true ? throw i : j..abs();
''';
    await resolveTestCode(code);
    await assertNoFix(
      errorFilter: (error) => error.offset == code.indexOf('j..'),
    );
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

  Future<void> test_else_if_false() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) {
    print('');
  } else if (false) {
    return;
  }
}
''');
    await assertHasFix('''
void f(bool b) {
  if (b) {
    print('');
  }
}
''');
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

  Future<void> test_if_false_block() async {
    await resolveTestCode('''
void f() {
  if (false) {
    return;
  }
  print('');
}
''');
    await assertHasFix('''
void f() {
  print('');
}
''');
  }

  Future<void> test_if_false_block_else_block() async {
    await resolveTestCode('''
void f() {
  if (false) {
    return;
  } else {
    print('1');
  }
  print('2');
}
''');
    await assertHasFix('''
void f() {
    print('1');
  print('2');
}
''');
  }

  Future<void> test_if_false_block_else_noBlock() async {
    await resolveTestCode('''
void f() {
  if (false) {
    return;
  } else print('1');
  print('2');
}
''');
    await assertHasFix('''
void f() {
  print('1');
  print('2');
}
''');
  }

  Future<void> test_if_false_noBlock() async {
    await resolveTestCode('''
void f() {
  if (false) return;
  print('');
}
''');
    await assertHasFix('''
void f() {
  print('');
}
''');
  }

  Future<void> test_if_false_noBlock_else_block() async {
    await resolveTestCode('''
void f() {
  if (false) return; else {
    print('1');
  }
  print('2');
}
''');
    await assertHasFix('''
void f() {
    print('1');
  print('2');
}
''');
  }

  Future<void> test_if_false_noBlock_else_noBlock() async {
    await resolveTestCode('''
void f() {
  if (false) return; else print('1');
  print('2');
}
''');
    await assertHasFix('''
void f() {
  print('1');
  print('2');
}
''');
  }

  Future<void> test_if_false_notInBlock() async {
    // Normally a statement like `if (true) { live; } else { dead; }` will be
    // fixed by removing the opening and closing braces around `live;`. But if
    // the parent of the if statement is not a block, this is not safe to do,
    // so the braces are kept.
    await resolveTestCode('''
void f() {
  while (true) if (true) {
    print('1');
  } else {
    return;
  }
}
''');
    await assertHasFix('''
void f() {
  while (true) {
    print('1');
  }
}
''');
  }

  Future<void> test_if_false_notRemovable() async {
    // Normally a statement like `if (false) dead;` can be removed. But if the
    // parent is not a block, it's not safe to do so.
    await resolveTestCode('''
void f() {
  while (true) if (false) return;
}
''');
    await assertNoFix();
  }

  Future<void> test_if_true_block_else_block() async {
    await resolveTestCode('''
void f() {
  if (true) {
    print('1');
  } else {
    return;
  }
  print('2');
}
''');
    await assertHasFix('''
void f() {
    print('1');
  print('2');
}
''');
  }

  Future<void> test_if_true_block_else_noBlock() async {
    await resolveTestCode('''
void f() {
  if (true) {
    print('1');
  } else return;
  print('2');
}
''');
    await assertHasFix('''
void f() {
    print('1');
  print('2');
}
''');
  }

  Future<void> test_if_true_noBlock_else_block() async {
    await resolveTestCode('''
void f() {
  if (true) print('1'); else {
    return;
  }
  print('2');
}
''');
    await assertHasFix('''
void f() {
  print('1');
  print('2');
}
''');
  }

  Future<void> test_if_true_noBlock_else_noBlock() async {
    await resolveTestCode('''
void f() {
  if (true) print('1'); else return;
  print('2');
}
''');
    await assertHasFix('''
void f() {
  print('1');
  print('2');
}
''');
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

  Future<void> test_conditional_unnecessaryNullCheck_equalsNull() async {
    await resolveTestCode(r'''
class C {
  String? s;
  void f(int i) {
    s = i == null ? null : '$i';
  }
}
''');
    await assertHasFix(r'''
class C {
  String? s;
  void f(int i) {
    s = '$i';
  }
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_conditional_unnecessaryNullCheck_notEqualsNull() async {
    await resolveTestCode(r'''
class C {
  String? s;
  void f(int i) {
    s = i != null ? '$i' : null;
  }
}
''');
    await assertHasFix(r'''
class C {
  String? s;
  void f(int i) {
    s = '$i';
  }
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_castEqualsNull() async {
    // Casts are presumed to be side effect free, so it is safe to remove
    // `if ((i as int) == null) return null;`
    await resolveTestCode(r'''
String? f(int? i) {
  if ((i as int) == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int? i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_castEqualsNull_withTargetSideEffect() async {
    // Casts are presumed to be side effect free, but only if the target of the
    // cast is side effect free. So it is not safe to remove
    // `if ((g(i) as int) == null) return null;`, because `g(i)` may have side
    // effects.
    await resolveTestCode(r'''
String? f(int i, int? Function(int) g) {
  if ((g(i) as int) == null) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_identifierEqualsNull() async {
    await resolveTestCode(r'''
String? f(int i) {
  if (i == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_nonNullAssertEqualsNull() async {
    // Non-null assertions are presumed to be side effect free, so it is safe to
    // remove `if (i! == null) return null;`
    await resolveTestCode(r'''
String? f(int? i) {
  if (i! == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int? i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_nonNullAssertEqualsNull_withTargetSideEffect() async {
    // Non-null assertions are presumed to be side effect free, but only if the
    // target of the assertion is side effect free. So it is not safe to remove
    // `if (g(i)! == null) return null;`, because `g(i)` may have side effects.
    await resolveTestCode(r'''
String? f(int i, int? Function(int) g) {
  if (g(i)! == null) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_nullEqualsPropertyAccess_withTargetSideEffect() async {
    // Getter invocations are presumed to be side effect free, but only if the
    // target of the invocation is side effect free. So it is not safe to remove
    // `if (null == g(i).isEven) return null;`, because `g(i)` may have side
    // effects.
    await resolveTestCode(r'''
String? f(int i, int Function(int) g) {
  if (null == g(i).isEven) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_postfixOperatorEqualsNull() async {
    // Postfix operators other than `!` are not side effect free, so it is not
    // safe to remove `if (i++ == null) return null;`.
    await resolveTestCode(r'''
String? f(int i) {
  if (i++ == null) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_prefixedIdentifierEqualsNull() async {
    // Getter invocations are presumed to be side effect free, so it is safe to
    // remove `if (i.isEven == null) return null;`.
    await resolveTestCode(r'''
String? f(int i) {
  if (i.isEven == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_propertyAccessEqualsNull() async {
    // Getter invocations are presumed to be side effect free, so it is safe to
    // remove `if ((i).isEven == null) return null;`.
    // Note: parentheses around `i` to force `.isEven` to be represented as a
    // PropertyAccess rather than a PrefixedIdentifier.
    await resolveTestCode(r'''
String? f(int i) {
  if ((i).isEven == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_propertyAccessEqualsNull_nullAware() async {
    // Getter invocations are presumed to be side effect free, so it is safe to
    // remove `if ((i?.isEven)! == null) return null;`.
    await resolveTestCode(r'''
String? f(int i) {
  if ((i?.isEven)! == null) return null;
  return '$i';
}
''');
    await assertHasFix(r'''
String? f(int i) {
  return '$i';
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void>
  test_if_propertyAccessEqualsNull_parenthesizedWithTargetSideEffect() async {
    // Getter invocations are presumed to be side effect free, but only if the
    // target of the invocation is side effect free. So it is not safe to remove
    // `if ((g(i)).isEven == null) return null;`, because `(g(i))` may have side
    // effects.
    await resolveTestCode(r'''
String? f(int i, int Function(int) g) {
  if ((g(i)).isEven == null) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_propertyAccessEqualsNull_super() async {
    // Getter invocations are presumed to be side effect free, so it is safe to
    // remove `if (super.foo == null) return null;`.
    await resolveTestCode(r'''
class B {
  int get foo => 0;
}
class C extends B {
  String? f() {
    if (super.foo == null) return null;
    return '${super.foo}';
  }
}
''');
    await assertHasFix(r'''
class B {
  int get foo => 0;
}
class C extends B {
  String? f() {
    return '${super.foo}';
  }
}
''', errorFilter: _ignoreNullSafetyWarnings);
  }

  Future<void> test_if_propertyAccessEqualsNull_withTargetSideEffect() async {
    // Getter invocations are presumed to be side effect free, but only if the
    // target of the invocation is side effect free. So it is not safe to remove
    // `if (g(i).isEven == null) return null;`, because `g(i)` may have side
    // effects.
    await resolveTestCode(r'''
String? f(int i, int Function(int) g) {
  if (g(i).isEven == null) return null;
  return '$i';
}
''');
    await assertNoFix(errorFilter: _ignoreNullSafetyWarnings);
  }

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
  bool _ignoreNullSafetyWarnings(Diagnostic diagnostic) =>
      !const {
        'DEAD_NULL_AWARE_EXPRESSION',
        'INVALID_NULL_AWARE_OPERATOR',
        'UNNECESSARY_NULL_COMPARISON',
      }.contains(diagnostic.diagnosticCode.name);
}
