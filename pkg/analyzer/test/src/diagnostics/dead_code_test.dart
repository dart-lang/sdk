// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadCodeTest);
    defineReflectiveTests(DeadCodeTest_Language219);
  });
}

@reflectiveTest
class DeadCodeTest extends PubPackageResolutionTest
    with DeadCodeTestCases_Language212 {
  test_asExpression_type() async {
    await assertErrorsInCode(
      r'''
Never doNotReturn() => throw 0;

test() => doNotReturn() as int;
''',
      [error(WarningCode.deadCode, 60, 4)],
    );
  }

  test_deadBlock_conditionalElse_recordPropertyAccess() async {
    await assertErrorsInCode(
      r'''
void f(({int x, int y}) p) {
  true ? p.x : p.y;
}
''',
      [error(WarningCode.deadCode, 44, 3)],
    );
  }

  test_deadOperandLHS_or_recordPropertyAccess() async {
    await assertErrorsInCode(
      r'''
void f(({bool b, }) r) {
  if (true || r.b) {}
}
''',
      [error(WarningCode.deadCode, 36, 6)],
    );
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case int() || 0) {}
}
''',
      [error(WarningCode.deadCode, 35, 4)],
    );
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case (int() || 0) && 1) {}
}
''',
      [error(WarningCode.deadCode, 36, 4)],
    );
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested2() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case <int>[int() || 0, 1]) {}
}
''',
      [error(WarningCode.deadCode, 45, 4)],
    );
  }

  test_deadPattern_switchExpression_logicalOrPattern() async {
    await assertErrorsInCode(
      r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
  };
}
''',
      [error(WarningCode.deadCode, 50, 4)],
    );
  }

  test_deadPattern_switchExpression_logicalOrPattern_nextCases() async {
    await assertErrorsInCode(
      r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
    int() => 1,
    _ => 2,
  };
}
''',
      [
        error(WarningCode.deadCode, 50, 4),
        error(WarningCode.deadCode, 65, 10),
        error(WarningCode.unreachableSwitchCase, 71, 2),
        error(WarningCode.deadCode, 81, 6),
        error(WarningCode.unreachableSwitchCase, 83, 2),
      ],
    );
  }

  test_deadPattern_switchStatement_logicalOrPattern() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case int() || 0:
      break;
  }
}
''',
      [error(WarningCode.deadCode, 46, 4)],
    );
  }

  test_deadPattern_switchStatement_nextCases() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case int() || 0:
    case 1:
    default:
      break;
  }
}
''',
      [
        error(WarningCode.deadCode, 46, 4),
        error(WarningCode.deadCode, 56, 4),
        error(WarningCode.unreachableSwitchCase, 56, 4),
        error(WarningCode.deadCode, 68, 7),
      ],
    );
  }

  test_deadPattern_switchStatement_nextCases2() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case int() || 42:
    case int() || 1:
    case 2:
      break;
  }
}
''',
      [
        error(WarningCode.deadCode, 46, 5),
        error(WarningCode.deadCode, 57, 4),
        error(WarningCode.unreachableSwitchCase, 57, 4),
        error(WarningCode.deadCode, 78, 4),
        error(WarningCode.unreachableSwitchCase, 78, 4),
      ],
    );
  }

  test_flowEnd_forElementParts_initializer_pattern_throw() async {
    await assertErrorsInCode(
      r'''
f() => [for (var (i) = throw 0; true; 1) 0];
''',
      [
        error(WarningCode.unusedLocalVariable, 18, 1),
        error(WarningCode.deadCode, 32, 7),
      ],
    );
  }

  test_flowEnd_forParts_initializer_pattern_throw() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var (i) = throw 0; true; 1) {}
}
''',
      [
        error(WarningCode.unusedLocalVariable, 23, 1),
        error(WarningCode.deadCode, 37, 7),
      ],
    );
  }

  test_forLoop_noUpdaters() async {
    await assertErrorsInCode(
      '''
Never foo() => throw "Never";

test() {
  int i = 0;
  for (foo(); (i = 42) < 0;) {}
  return i;
}
''',
      [error(WarningCode.deadCode, 67, 29)],
    );
  }

  test_ifElement_patternAssignment() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  [if (false) (a) = 0];
}
''',
      [error(WarningCode.deadCode, 30, 7)],
    );
  }

  test_isExpression_type() async {
    await assertErrorsInCode(
      r'''
Never doNotReturn() => throw 0;

test() => doNotReturn() is int;
''',
      [
        error(WarningCode.unnecessaryTypeCheckTrue, 43, 20),
        error(WarningCode.deadCode, 60, 4),
      ],
    );
  }

  test_localFunction_wildcard() async {
    await assertErrorsInCode(
      r'''
void f() {
  _(){}
}
''',
      [error(WarningCode.deadCode, 13, 5)],
    );
  }

  test_localFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  _(){}
}
''',
      [
        // No dead code.
        error(WarningCode.unusedElement, 57, 1),
      ],
    );
  }

  test_nullAwareIndexedRead() async {
    await assertErrorsInCode(
      r'''
void f(Null n, int i) {
  n?[i];
  print('reached');
}
''',
      [
        // Dead range: `i]`
        error(WarningCode.deadCode, 29, 2),
      ],
    );
  }

  test_nullAwareIndexedWrite() async {
    await assertErrorsInCode(
      r'''
void f(Null n, int i, int j) {
  n?[i] = j;
  print('reached');
}
''',
      [
        // Dead range: `i] = j`
        error(WarningCode.deadCode, 36, 6),
      ],
    );
  }

  test_nullAwareMethodInvocation() async {
    await assertErrorsInCode(
      r'''
void f(Null n, int i) {
  n?.foo(i);
  print('reached');
}
''',
      [
        // Dead range: `foo(i)`
        error(WarningCode.deadCode, 29, 6),
      ],
    );
  }

  test_nullAwarePropertyRead() async {
    await assertErrorsInCode(
      r'''
void f(Null n) {
  n?.p;
  print('reached');
}
''',
      [
        // Dead range: `p`
        error(WarningCode.deadCode, 22, 1),
      ],
    );
  }

  test_nullAwarePropertyWrite() async {
    await assertErrorsInCode(
      r'''
void f(Null n, int i) {
  n?.p = i;
  print('reached');
}
''',
      [
        // Dead range: `p = i`
        error(WarningCode.deadCode, 29, 5),
      ],
    );
  }

  test_objectPattern_neverTypedGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  Never get foo => throw 0;
}

void f(Object x) {
  if (x case A(foo: _)) {}
}
''',
      [error(WarningCode.deadCode, 84, 2)],
    );
  }

  test_prefixedIdentifier_identifier() async {
    await assertErrorsInCode(
      r'''
Never get doNotReturn => throw 0;

test() => doNotReturn.hashCode;
''',
      [error(WarningCode.deadCode, 57, 9)],
    );
  }

  test_propertyAccess_property() async {
    await assertErrorsInCode(
      r'''
Never doNotReturn() => throw 0;

test() => doNotReturn().hashCode;
''',
      [error(WarningCode.deadCode, 57, 9)],
    );
  }
}

@reflectiveTest
class DeadCodeTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin, DeadCodeTestCases_Language212 {
  @override
  test_lateWildCardVariable_initializer() async {
    await assertNoErrorsInCode(r'''
f() {
  // Not a wildcard variable.
  late var _ = 0;
}
''');
  }
}

mixin DeadCodeTestCases_Language212 on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_afterForEachWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f(List<Object> values) {
  named: {
    for (var x in values) {
      if (x == 42) {
        break named;
      }
    }
    return;
  }
  print('not dead');
}
''');
  }

  test_afterForWithBreakLabel() async {
    await assertNoErrorsInCode(r'''
f() {
  named: {
    for (int i = 0; i < 7; i++) {
      if (i == 42)
        break named;
    }
    return;
  }
  print('not dead');
}
''');
  }

  test_afterTryCatch() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
    return f();
  } catch (e) {
    print(e);
  }
  print('not dead');
}
f() {
  throw 'foo';
}
''');
  }

  test_assert() async {
    await assertErrorsInCode(
      r'''
void f() {
  return;
  assert (true);
}
''',
      [error(WarningCode.deadCode, 23, 14)],
    );
  }

  test_assert_dead_message() async {
    // We don't warn if an assert statement is live but its message is dead,
    // because this results in nuisance warnings for desirable assertions (e.g.
    // a `!= null` assertion that is redundant with strong checking but still
    // useful with weak checking).
    await assertErrorsInCode(
      '''
void f(Object waldo) {
  assert(waldo != null, "Where's Waldo?");
}
''',
      [error(WarningCode.unnecessaryNullComparisonNeverNullTrue, 38, 7)],
    );
  }

  test_assigned_methodInvocation() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i = 1;
  i?.truncate();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 28, 2)],
    );
  }

  test_class_field_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await assertErrorsInCode(
      '''
Never f() { throw ''; }

class C {
  static final x = [1, 2, f(), 4];
}
''',
      [error(WarningCode.deadCode, 66, 2)],
    );
  }

  test_constructorInitializerWithThrow_thenBlockBody() async {
    await assertErrorsInCode(
      r'''
class A {
  int x;
  A() : x = throw 0 {
    x;
  }
}
''',
      [error(WarningCode.deadCode, 39, 12)],
    );
  }

  test_constructorInitializerWithThrow_thenEmptyBlockBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A() : x = throw 0 {}
}
''');
  }

  test_constructorInitializerWithThrow_thenEmptyBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A() : x = throw 0;
}
''');
  }

  test_constructorInitializerWithThrow_thenExpressions() async {
    await assertErrorsInCode(
      r'''
class A {
  var x = [8];
  A() : x = [7, throw 8, 9];
}
''',
      [error(WarningCode.deadCode, 50, 3)],
    );
  }

  test_constructorInitializerWithThrow_thenInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  int x;
  int y;
  A()
      : x = throw 0,
        y = 7;
}
''',
      [error(WarningCode.deadCode, 63, 5)],
    );
  }

  test_continueInSwitch() async {
    await assertNoErrorsInCode(r'''
void f(int i) {
  for (;; 1) {
    switch (i) {
      default:
        continue;
    }
  }
}
''');
  }

  test_deadBlock_conditionalElse() async {
    await assertErrorsInCode(
      r'''
f() {
  true ? 1 : 2;
}
''',
      [error(WarningCode.deadCode, 19, 1)],
    );
  }

  test_deadBlock_conditionalElse_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}
''');
  }

  test_deadBlock_conditionalElse_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  true ? true : false && false;
}
''',
      [error(WarningCode.deadCode, 22, 14)],
    );
  }

  test_deadBlock_conditionalThen() async {
    await assertErrorsInCode(
      r'''
f() {
  false ? 1 : 2;
}
''',
      [error(WarningCode.deadCode, 16, 1)],
    );
  }

  test_deadBlock_conditionalThen_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}
''');
  }

  test_deadBlock_conditionalThen_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  false ? false && false : true;
}
''',
      [error(WarningCode.deadCode, 16, 14)],
    );
  }

  test_deadBlock_else() async {
    await assertErrorsInCode(
      r'''
f() {
  if(true) {} else {}
}
''',
      [error(WarningCode.deadCode, 25, 2)],
    );
  }

  test_deadBlock_else_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}
''');
  }

  test_deadBlock_else_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  if(true) {} else {if (false) {}}
}
''',
      [error(WarningCode.deadCode, 25, 15)],
    );
  }

  test_deadBlock_if() async {
    await assertErrorsInCode(
      r'''
f() {
  if(false) {}
}
''',
      [error(WarningCode.deadCode, 18, 2)],
    );
  }

  test_deadBlock_if_debugConst_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}
''');
  }

  test_deadBlock_if_debugConst_prefixedIdentifier2() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
class A {
  static const bool DEBUG = false;
}''');
    await assertNoErrorsInCode(r'''
import 'lib2.dart';
f() {
  if(A.DEBUG) {}
}
''');
  }

  test_deadBlock_if_debugConst_propertyAccessor() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
class A {
  static const bool DEBUG = false;
}
''');
    await assertNoErrorsInCode(r'''
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}
''');
  }

  test_deadBlock_if_debugConst_simpleIdentifier() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}
''');
  }

  test_deadBlock_if_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  if(false) {if(false) {}}
}
''',
      [error(WarningCode.deadCode, 18, 14)],
    );
  }

  test_deadBlock_ifElement() async {
    await assertErrorsInCode(
      r'''
f() {
  [
    if (false) 2,
  ];
}
''',
      [error(WarningCode.deadCode, 25, 1)],
    );
  }

  test_deadBlock_ifElement_else() async {
    await assertErrorsInCode(
      r'''
f() {
  [
    if (true) 2
    else 3,
  ];
}
''',
      [error(WarningCode.deadCode, 35, 1)],
    );
  }

  test_deadBlock_while() async {
    await assertErrorsInCode(
      r'''
f() {
  while(false) {}
}
''',
      [error(WarningCode.deadCode, 21, 2)],
    );
  }

  test_deadBlock_while_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}
''');
  }

  test_deadBlock_while_nested() async {
    // Test that a dead while body can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  while(false) {if(false) {}}
}
''',
      [error(WarningCode.deadCode, 21, 14)],
    );
  }

  test_deadCatch_catchFollowingCatch() async {
    await assertErrorsInCode(
      r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}
''',
      [error(WarningCode.deadCodeCatchFollowingCatch, 39, 12)],
    );
  }

  test_deadCatch_catchFollowingCatch_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(
      r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}
''',
      [error(WarningCode.deadCodeCatchFollowingCatch, 39, 24)],
    );
  }

  test_deadCatch_catchFollowingCatch_object() async {
    await assertErrorsInCode(
      r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}
''',
      [
        error(WarningCode.unusedCatchClause, 32, 1),
        error(WarningCode.deadCodeCatchFollowingCatch, 38, 12),
      ],
    );
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(
      r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}
''',
      [
        error(WarningCode.unusedCatchClause, 32, 1),
        error(WarningCode.deadCodeCatchFollowingCatch, 38, 24),
      ],
    );
  }

  test_deadCatch_onCatchSubtype() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}
''',
      [
        error(WarningCode.unusedCatchClause, 59, 1),
        error(WarningCode.deadCodeOnCatchSubtype, 65, 17),
        error(WarningCode.unusedCatchClause, 77, 1),
      ],
    );
  }

  test_deadCatch_onCatchSubtype_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}
''',
      [
        error(WarningCode.unusedCatchClause, 59, 1),
        error(WarningCode.deadCodeOnCatchSubtype, 65, 29),
        error(WarningCode.unusedCatchClause, 77, 1),
      ],
    );
  }

  test_deadCatch_onCatchSupertype() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}
''',
      [
        error(WarningCode.unusedCatchClause, 59, 1),
        error(WarningCode.unusedCatchClause, 77, 1),
      ],
    );
  }

  test_deadOperandLHS_and() async {
    await assertErrorsInCode(
      r'''
f() {
  bool b = false && false;
  print(b);
}
''',
      [error(WarningCode.deadCode, 23, 8)],
    );
  }

  test_deadOperandLHS_and_debugConst() async {
    await assertNoErrorsInCode(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
  print(b);
}
''');
  }

  test_deadOperandLHS_and_nested() async {
    await assertErrorsInCode(
      r'''
f() {
  bool b = false && (false && false);
  print(b);
}
''',
      [error(WarningCode.deadCode, 23, 19)],
    );
  }

  test_deadOperandLHS_or() async {
    await assertErrorsInCode(
      r'''
f() {
  bool b = true || true;
  print(b);
}
''',
      [error(WarningCode.deadCode, 22, 7)],
    );
  }

  test_deadOperandLHS_or_debugConst() async {
    await assertErrorsInCode(
      r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}
''',
      [error(WarningCode.unusedLocalVariable, 38, 1)],
    );
  }

  test_deadOperandLHS_or_nested() async {
    await assertErrorsInCode(
      r'''
f() {
  bool b = true || (false && false);
  print(b);
}
''',
      [error(WarningCode.deadCode, 22, 19)],
    );
  }

  test_documentationComment() async {
    await assertNoErrorsInCode(r'''
/// text
int f() => 0;
''');
  }

  test_doWhile() async {
    await assertErrorsInCode(
      r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
}
''',
      [error(WarningCode.deadCode, 52, 12)],
    );
  }

  test_doWhile_break() async {
    await assertErrorsInCode(
      r'''
void f(bool c) {
  do {
    if (c) {
     break;
    }
    return;
  } while (c);
  print('');
}
''',
      [error(WarningCode.deadCode, 69, 12)],
    );
  }

  test_doWhile_break_doLabel() async {
    await assertErrorsInCode(
      r'''
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
''',
      [error(WarningCode.deadCode, 85, 12)],
    );
  }

  test_doWhile_break_inner() async {
    await assertErrorsInCode(
      r'''
void f(bool c) {
  do {
    while (c) {
      break;
    }
    return;
  } while (c);
  print('');
}
''',
      [
        error(WarningCode.deadCode, 73, 12),
        error(WarningCode.deadCode, 88, 10),
      ],
    );
  }

  Future<void> test_doWhile_break_outerDoLabel() async {
    await assertErrorsInCode(
      r'''
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
''',
      [
        error(WarningCode.deadCode, 104, 12),
        error(WarningCode.deadCode, 121, 38),
      ],
    );
  }

  Future<void> test_doWhile_break_outerLabel() async {
    await assertErrorsInCode(
      r'''
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
''',
      [
        error(WarningCode.deadCode, 98, 12),
        error(WarningCode.deadCode, 115, 14),
      ],
    );
  }

  test_doWhile_statements() async {
    await assertErrorsInCode(
      r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
  print('2');
}
''',
      [
        error(WarningCode.deadCode, 52, 12),
        error(WarningCode.deadCode, 67, 11),
      ],
    );
  }

  test_flowEnd_block_forStatement_updaters() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (;; 1) {
    return;
    2;
  }
}
''',
      [error(WarningCode.deadCode, 21, 1), error(WarningCode.deadCode, 42, 2)],
    );
  }

  test_flowEnd_block_forStatement_updaters_multiple() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (;; 1, 2) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 21, 4)],
    );
  }

  test_flowEnd_forElementParts_condition_exists() async {
    await assertErrorsInCode(
      r'''
f() => [for (; throw 0; 1) 0];
''',
      [error(WarningCode.deadCode, 24, 1), error(WarningCode.deadCode, 27, 3)],
    );
  }

  test_flowEnd_forElementParts_condition_throw() async {
    await assertErrorsInCode(
      r'''
f(bool Function(Object?, Object?) g) => [for (; g(throw 0, 1); 2) 0];
''',
      [error(WarningCode.deadCode, 59, 10)],
    );
  }

  test_flowEnd_forElementParts_initializer_declaration_throw() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = throw 0; true; 1) 0];
''',
      [
        error(WarningCode.unusedLocalVariable, 17, 1),
        error(WarningCode.deadCode, 30, 7),
      ],
    );
  }

  test_flowEnd_forElementParts_initializer_expression_throw() async {
    await assertErrorsInCode(
      r'''
f() => [for (throw 0; true; 1) 0];
''',
      [error(WarningCode.deadCode, 22, 7)],
    );
  }

  test_flowEnd_forElementParts_updaters_assignmentExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i = i + 1) throw ''];
''',
      [error(WarningCode.deadCode, 25, 9)],
    );
  }

  test_flowEnd_forElementParts_updaters_binaryExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i + 1) throw ''];
''',
      [error(WarningCode.deadCode, 25, 5)],
    );
  }

  test_flowEnd_forElementParts_updaters_cascadeExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i..sign) throw ''];
''',
      [error(WarningCode.deadCode, 25, 7)],
    );
  }

  test_flowEnd_forElementParts_updaters_conditionalExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i > 1 ? i : i) throw ''];
''',
      [error(WarningCode.deadCode, 25, 13)],
    );
  }

  test_flowEnd_forElementParts_updaters_indexExpression() async {
    await assertErrorsInCode(
      r'''
f(List<int> values) => [for (;; values[0]) throw ''];
''',
      [error(WarningCode.deadCode, 32, 9)],
    );
  }

  test_flowEnd_forElementParts_updaters_instanceCreationExpression() async {
    await assertErrorsInCode(
      r'''
class C {}
f() => [for (;; C()) throw ''];
''',
      [error(WarningCode.deadCode, 27, 3)],
    );
  }

  test_flowEnd_forElementParts_updaters_methodInvocation() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i.toString()) throw ''];
''',
      [error(WarningCode.deadCode, 25, 12)],
    );
  }

  test_flowEnd_forElementParts_updaters_postfixExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; i++) throw ''];
''',
      [error(WarningCode.deadCode, 25, 3)],
    );
  }

  test_flowEnd_forElementParts_updaters_prefixedIdentifier() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as m;

f() => [for (;; m.Point) throw ''];
''',
      [error(WarningCode.deadCode, 42, 7)],
    );
  }

  test_flowEnd_forElementParts_updaters_prefixExpression() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; ++i) throw ''];
''',
      [error(WarningCode.deadCode, 25, 3)],
    );
  }

  test_flowEnd_forElementParts_updaters_propertyAccess() async {
    await assertErrorsInCode(
      r'''
f() => [for (var i = 0;; (i).sign) throw ''];
''',
      [error(WarningCode.deadCode, 25, 8)],
    );
  }

  test_flowEnd_forElementParts_updaters_throw() async {
    await assertErrorsInCode(
      r'''
f() => [for (;; 0, throw 1, 2) 0];
''',
      [error(WarningCode.deadCode, 28, 1)],
    );
  }

  test_flowEnd_forParts_condition_exists() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (; throw 0; 1) {}
}
''',
      [error(WarningCode.deadCode, 29, 1), error(WarningCode.deadCode, 32, 2)],
    );
  }

  test_flowEnd_forParts_condition_throw() async {
    await assertErrorsInCode(
      r'''
void f(bool Function(Object?, Object?) g) {
  for (; g(throw 0, 1); 2) {}
}
''',
      [error(WarningCode.deadCode, 64, 9)],
    );
  }

  test_flowEnd_forParts_initializer_declaration_throw() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = throw 0; true; 1) {}
}
''',
      [
        error(WarningCode.unusedLocalVariable, 22, 1),
        error(WarningCode.deadCode, 35, 7),
      ],
    );
  }

  test_flowEnd_forParts_initializer_expression_throw() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (throw 0; true; 1) {}
}
''',
      [error(WarningCode.deadCode, 27, 7)],
    );
  }

  test_flowEnd_forParts_updaters_assignmentExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i = i + 1) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 9)],
    );
  }

  test_flowEnd_forParts_updaters_binaryExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i + 1) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 5)],
    );
  }

  test_flowEnd_forParts_updaters_cascadeExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i..sign) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 7)],
    );
  }

  test_flowEnd_forParts_updaters_conditionalExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i > 1 ? i : i) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 13)],
    );
  }

  test_flowEnd_forParts_updaters_indexExpression() async {
    await assertErrorsInCode(
      r'''
void f(List<int> values) {
  for (;; values[0]) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 37, 9)],
    );
  }

  test_flowEnd_forParts_updaters_instanceCreationExpression() async {
    await assertErrorsInCode(
      r'''
class C {}
void f() {
  for (;; C()) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 32, 3)],
    );
  }

  test_flowEnd_forParts_updaters_methodInvocation() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i.toString()) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 12)],
    );
  }

  test_flowEnd_forParts_updaters_postfixExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; i++) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 3)],
    );
  }

  test_flowEnd_forParts_updaters_prefixedIdentifier() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as m;

void f() {
  for (;; m.Point) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 47, 7)],
    );
  }

  test_flowEnd_forParts_updaters_prefixExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; ++i) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 3)],
    );
  }

  test_flowEnd_forParts_updaters_propertyAccess() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var i = 0;; (i).sign) {
    return;
  }
}
''',
      [error(WarningCode.deadCode, 30, 8)],
    );
  }

  test_flowEnd_forParts_updaters_throw() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (;; 0, throw 1, 2) {}
}
''',
      [error(WarningCode.deadCode, 33, 1)],
    );
  }

  test_flowEnd_forStatement() async {
    await assertErrorsInCode(
      r'''
main() {
  for (var v in [0, 1, 2]) {
    v;
    return;
    1;
  }
  2;
}
''',
      [error(WarningCode.deadCode, 61, 2)],
    );
  }

  test_flowEnd_ifStatement() async {
    await assertErrorsInCode(
      r'''
void f(bool a) {
  if (a) {
    return;
    1;
  }
  2;
}
''',
      [error(WarningCode.deadCode, 44, 2)],
    );
  }

  test_flowEnd_list_forElement_updaters() async {
    await assertErrorsInCode(
      r'''
f() => [for (;; 1) ...[throw '', 2]];
''',
      [error(WarningCode.deadCode, 16, 1), error(WarningCode.deadCode, 33, 4)],
    );
  }

  test_flowEnd_list_forElement_updaters_multiple() async {
    await assertErrorsInCode(
      r'''
f() => [for (;; 1, 2) ...[throw '']];
''',
      [error(WarningCode.deadCode, 16, 4)],
    );
  }

  test_flowEnd_nestedBlock_forStatement_updaters() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (;; 1) {
    {
      return;
      2;
    }
  }
}
''',
      [error(WarningCode.deadCode, 21, 1), error(WarningCode.deadCode, 52, 8)],
    );
  }

  test_flowEnd_nestedBlock_forStatement_updaters_multiple() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (;; 1, 2) {
    {
      return;
    }
  }
}
''',
      [error(WarningCode.deadCode, 21, 4)],
    );
  }

  test_flowEnd_tryStatement_body() async {
    await assertErrorsInCode(
      r'''
Never foo() => throw 0;

main() {
  try {
    foo();
    1;
  } catch (_) {
    2;
  }
  3;
}
''',
      [error(WarningCode.deadCode, 57, 2)],
    );
  }

  test_flowEnd_tryStatement_catchClause() async {
    await assertErrorsInCode(
      r'''
main() {
  try {
    1;
  } catch (_) {
    return;
    2;
  }
  3;
}
''',
      [error(WarningCode.deadCode, 56, 2)],
    );
  }

  test_flowEnd_tryStatement_finally() async {
    await assertErrorsInCode(
      r'''
main() {
  try {
    1;
  } finally {
    2;
    return;
    3;
  }
  4;
}
''',
      [error(WarningCode.deadCode, 61, 11)],
    );
  }

  test_forStatement() async {
    await assertErrorsInCode(
      r'''
void f() {
  return;
  for (;;) {}
}
''',
      [error(WarningCode.deadCode, 23, 11)],
    );
  }

  test_ifStatement_noCase_conditionFalse() async {
    await assertErrorsInCode(
      r'''
void f() {
  if (false) {
    1;
  } else {
    2;
  }
  3;
}
''',
      [error(WarningCode.deadCode, 24, 12)],
    );
  }

  test_ifStatement_noCase_conditionTrue() async {
    await assertErrorsInCode(
      r'''
void f() {
  if (true) {
    1;
  } else {
    2;
  }
  3;
}
''',
      [error(WarningCode.deadCode, 41, 12)],
    );
  }

  test_invokeNever_functionExpressionInvocation_getter_propertyAccess() async {
    await assertErrorsInCode(
      r'''
class A {
  Never get f => throw 0;
}
void g(A a) {
  a.f(0);
  print(1);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 54, 3),
        error(WarningCode.deadCode, 57, 16),
      ],
    );
  }

  test_invokeNever_functionExpressionInvocation_parenthesizedExpression() async {
    await assertErrorsInCode(
      r'''
void g(Never f) {
  (f)(0);
  print(1);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 3),
        error(WarningCode.deadCode, 23, 16),
      ],
    );
  }

  test_invokeNever_functionExpressionInvocation_simpleIdentifier() async {
    await assertErrorsInCode(
      r'''
void g(Never f) {
  f(0);
  print(1);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 21, 16),
      ],
    );
  }

  test_lateWildCardVariable_initializer() async {
    await assertErrorsInCode(
      r'''
f() {
  late var _ = 0;
}
''',
      [error(WarningCode.deadCodeLateWildcardVariableInitializer, 21, 1)],
    );
  }

  test_lateWildCardVariable_noInitializer() async {
    await assertNoErrorsInCode(r'''
f() {
  late var _;
}
''');
  }

  test_notUnassigned_propertyAccess() async {
    await assertNoErrorsInCode(r'''
void f(int? i) {
  (i)?.sign;
}
''');
  }

  test_potentiallyAssigned_propertyAccess() async {
    await assertNoErrorsInCode(r'''
void f(bool b) {
  int? i;
  if (b) {
    i = 1;
  }
  (i)?.sign;
}
''');
  }

  test_returnTypeNever_function() async {
    await assertErrorsInCode(
      r'''
Never foo() => throw 0;

main() {
  foo();
  1;
}
''',
      [error(WarningCode.deadCode, 45, 2)],
    );
  }

  test_returnTypeNever_getter() async {
    await assertErrorsInCode(
      r'''
Never get foo => throw 0;

main() {
  foo;
  2;
}
''',
      [error(WarningCode.deadCode, 45, 2)],
    );
  }

  @failingTest
  test_statementAfterAlwaysThrowsGetter() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  int get a {
    throw 'msg';
  }

f() {
  print(1);
  new C().a;
  print(2);
}
''',
      [error(WarningCode.deadCode, 129, 9)],
    );
  }

  test_statementAfterBreak_inDefaultCase() async {
    await assertErrorsInCode(
      r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      print(1);
  }
}
''',
      [error(WarningCode.deadCode, 65, 9)],
    );
  }

  test_statementAfterBreak_inForEachStatement() async {
    await assertErrorsInCode(
      r'''
f() {
  var list;
  for(var l in list) {
    break;
    print(l);
  }
}
''',
      [error(WarningCode.deadCode, 56, 9)],
    );
  }

  test_statementAfterBreak_inForStatement() async {
    await assertErrorsInCode(
      r'''
f() {
  for(;;) {
    break;
    print(1);
  }
}
''',
      [error(WarningCode.deadCode, 33, 9)],
    );
  }

  test_statementAfterBreak_inSwitchCase() async {
    await assertErrorsInCode(
      r'''
f(v) {
  switch(v) {
    case 1:
      break;
      print(1);
  }
}
''',
      [error(WarningCode.deadCode, 52, 9)],
    );
  }

  test_statementAfterBreak_inWhileStatement() async {
    await assertErrorsInCode(
      r'''
f(v) {
  while(v) {
    break;
    print(1);
  }
}
''',
      [error(WarningCode.deadCode, 35, 9)],
    );
  }

  test_statementAfterContinue_inForEachStatement() async {
    await assertErrorsInCode(
      r'''
f() {
  var list;
  for(var l in list) {
    continue;
    print(l);
  }
}
''',
      [error(WarningCode.deadCode, 59, 9)],
    );
  }

  test_statementAfterContinue_inForStatement() async {
    await assertErrorsInCode(
      r'''
f() {
  for(;;) {
    continue;
    print(1);
  }
}
''',
      [error(WarningCode.deadCode, 36, 9)],
    );
  }

  test_statementAfterContinue_inWhileStatement() async {
    await assertErrorsInCode(
      r'''
f(v) {
  while(v) {
    continue;
    print(1);
  }
}
''',
      [error(WarningCode.deadCode, 38, 9)],
    );
  }

  test_statementAfterExitingIf_returns() async {
    await assertErrorsInCode(
      r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  print(1);
}
''',
      [error(WarningCode.deadCode, 62, 9)],
    );
  }

  test_statementAfterIfWithoutElse() async {
    await assertNoErrorsInCode(r'''
f() {
  if (1 < 0) {
    return;
  }
  print(1);
}
''');
  }

  test_statementAfterRethrow() async {
    await assertErrorsInCode(
      r'''
f() {
  try {
    print(1);
  } catch (e) {
    rethrow;
    print(2);
  }
}
''',
      [error(WarningCode.deadCode, 61, 9)],
    );
  }

  test_statementAfterReturn_function() async {
    await assertErrorsInCode(
      r'''
f() {
  print(1);
  return;
  print(2);
}
''',
      [error(WarningCode.deadCode, 30, 9)],
    );
  }

  test_statementAfterReturn_function_local() async {
    await assertErrorsInCode(
      r'''
f() {
  void g() {
    print(1);
    return;
    print(2);
  }
  g();
}
''',
      [error(WarningCode.deadCode, 49, 9)],
    );
  }

  test_statementAfterReturn_functionExpression() async {
    await assertErrorsInCode(
      r'''
f() {
  () {
    print(1);
    return;
    print(2);
  };
}
''',
      [error(WarningCode.deadCode, 43, 9)],
    );
  }

  test_statementAfterReturn_ifStatement() async {
    await assertErrorsInCode(
      r'''
f(bool b) {
  if(b) {
    print(1);
    return;
    print(2);
  }
}
''',
      [error(WarningCode.deadCode, 52, 9)],
    );
  }

  test_statementAfterReturn_method() async {
    await assertErrorsInCode(
      r'''
class A {
  m() {
    print(1);
    return;
    print(2);
  }
}
''',
      [error(WarningCode.deadCode, 48, 9)],
    );
  }

  test_statementAfterReturn_nested() async {
    await assertErrorsInCode(
      r'''
f() {
  print(1);
  return;
  if(false) {}
}
''',
      [error(WarningCode.deadCode, 30, 12)],
    );
  }

  test_statementAfterReturn_twoReturns() async {
    await assertErrorsInCode(
      r'''
f() {
  print(1);
  return;
  print(2);
  return;
  print(3);
}
''',
      [error(WarningCode.deadCode, 30, 31)],
    );
  }

  test_statementAfterThrow() async {
    await assertErrorsInCode(
      r'''
f() {
  print(1);
  throw 'Stop here';
  print(2);
}
''',
      [error(WarningCode.deadCode, 41, 9)],
    );
  }

  test_switchCase_final_break() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      break;
  }
}
''',
      [error(WarningCode.deadCode, 96, 6)],
    );
  }

  test_switchCase_final_continue() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  for (var i = 0; i < 2; i++) {
    switch (a) {
      case 0:
        try {} finally {
          return;
        }
        continue;
    }
  }
}
''',
      [error(WarningCode.deadCode, 140, 9)],
    );
  }

  test_switchCase_final_rethrow() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  try {
    // empty
  } on int {
    switch (a) {
      case 0:
        try {} finally {
          return;
        }
        rethrow;
    }
  }
}
''',
      [error(WarningCode.deadCode, 142, 8)],
    );
  }

  test_switchCase_final_return() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      return;
  }
}
''',
      [error(WarningCode.deadCode, 96, 7)],
    );
  }

  test_switchCase_final_throw() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      throw 0;
  }
}
''',
      [error(WarningCode.deadCode, 96, 8)],
    );
  }

  test_switchStatement_exhaustive() async {
    await assertErrorsInCode(
      r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a: return 0;
    case Foo.b: return 1;
  }
  return -1;
}
''',
      [error(WarningCode.deadCode, 111, 10)],
    );
  }

  test_topLevelVariable_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await assertErrorsInCode(
      '''
Never f() { throw ''; }

var x = [1, 2, f(), 4];
''',
      [error(WarningCode.deadCode, 45, 2)],
    );
  }

  test_try_finally() async {
    await assertErrorsInCode(
      '''
main() {
  try {
    foo();
    print('dead');
  } finally {
    print('alive');
  }
  print('dead');
}
Never foo() => throw 'exception';
''',
      [
        error(WarningCode.deadCode, 32, 14),
        error(WarningCode.deadCode, 87, 14),
      ],
    );
  }

  test_unassigned_cascadeExpression_indexExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  List<int>? l;
  l?..[0]..length;
}
''',
      [error(WarningCode.deadCode, 30, 14)],
    );
  }

  test_unassigned_cascadeExpression_methodInvocation() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  i?..toInt()..isEven;
}
''',
      [error(WarningCode.deadCode, 24, 18)],
    );
  }

  test_unassigned_cascadeExpression_propertyAccess() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  i?..sign..isEven;
}
''',
      [error(WarningCode.deadCode, 24, 15)],
    );
  }

  test_unassigned_indexExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  List<int>? l;
  l?[0];
}
''',
      [error(WarningCode.deadCode, 30, 4)],
    );
  }

  test_unassigned_indexExpression_indexExpression() async {
    await assertErrorsInCode(
      r'''
void f() {
  List<List<int>>? l;
  l?[0][0];
}
''',
      [error(WarningCode.deadCode, 36, 7)],
    );
  }

  test_unassigned_methodInvocation() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  i?.truncate();
}
''',
      [error(WarningCode.deadCode, 24, 12)],
    );
  }

  test_unassigned_methodInvocation_methodInvocation() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  i?.truncate().truncate();
}
''',
      [error(WarningCode.deadCode, 24, 23)],
    );
  }

  test_unassigned_methodInvocation_propertyAccess() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  i?.truncate().sign;
}
''',
      [error(WarningCode.deadCode, 24, 17)],
    );
  }

  test_unassigned_propertyAccess() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  (i)?.sign;
}
''',
      [error(WarningCode.deadCode, 26, 6)],
    );
  }

  test_unassigned_propertyAccess_propertyAccess() async {
    await assertErrorsInCode(
      r'''
void f() {
  int? i;
  (i)?.sign.sign;
}
''',
      [error(WarningCode.deadCode, 26, 11)],
    );
  }

  test_yield() async {
    await assertErrorsInCode(
      r'''
Iterable<int> f() sync* {
  return;
  yield 1;
}
''',
      [error(WarningCode.deadCode, 38, 8)],
    );
  }
}
