// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadCodeTest);
    defineReflectiveTests(DeadCodeTest_Language219);
    defineReflectiveTests(DeadCodeTest_AnonymousMethodsExperiment);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeadCodeTest extends PubPackageResolutionTest
    with DeadCodeTestCases_Language212 {
  test_asExpression_type() async {
    await resolveTestCodeWithDiagnostics(r'''
Never doNotReturn() => throw 0;

test() => doNotReturn() as int;
//                         ^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_deadBlock_conditionalElse_recordPropertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({int x, int y}) p) {
  true ? p.x : p.y;
//             ^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadOperandLHS_or_recordPropertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(({bool b, }) r) {
  if (true || r.b) {}
//         ^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case int() || 0) {}
//                 ^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case (int() || 0) && 1) {}
//                  ^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadPattern_ifCase_logicalOrPattern_leftAlwaysMatches_nested2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case <int>[int() || 0, 1]) {}
//                       ^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadPattern_switchExpression_logicalOrPattern() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
//        ^^^^
// [diag.deadCode] Dead code.
  };
}
''');
  }

  test_deadPattern_switchExpression_logicalOrPattern_nextCases() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(int x) {
  return switch (x) {
    int() || 0 => 0,
//        ^^^^
// [diag.deadCode] Dead code.
    int() => 1,
//  ^^^^^^^^^^
// [diag.deadCode] Dead code.
//        ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    _ => 2,
//  ^^^^^^
// [diag.deadCode] Dead code.
//    ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
  };
}
''');
  }

  test_deadPattern_switchStatement_logicalOrPattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case int() || 0:
//             ^^^^
// [diag.deadCode] Dead code.
      break;
  }
}
''');
  }

  test_deadPattern_switchStatement_nextCases() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case int() || 0:
//             ^^^^
// [diag.deadCode] Dead code.
    case 1:
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    default:
//  ^^^^^^^
// [diag.deadCode] Dead code.
      break;
  }
}
''');
  }

  test_deadPattern_switchStatement_nextCases2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case int() || 42:
//             ^^^^^
// [diag.deadCode] Dead code.
    case int() || 1:
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    case 2:
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
      break;
  }
}
''');
  }

  test_flowEnd_forElementParts_initializer_pattern_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var (i) = throw 0; true; 1) 0];
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                              ^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forParts_initializer_pattern_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (i) = throw 0; true; 1) {}
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                        ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_forLoop_noUpdaters() async {
    await resolveTestCodeWithDiagnostics(r'''
Never foo() => throw "Never";

test() {
  int i = 0;
  for (foo(); (i = 42) < 0;) {}
// [diag.deadCode][column 15][length 29] Dead code.
  return i;
}
''');
  }

  test_ifElement_patternAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  [if (false) (a) = 0];
//            ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_isExpression_type() async {
    await resolveTestCodeWithDiagnostics(r'''
Never doNotReturn() => throw 0;

test() => doNotReturn() is int;
//        ^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
//                         ^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_localFunction_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  _(){}
//^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_localFunction_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  _(){}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');
  }

  test_nullAwareIndexedRead() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null n, int i) {
  n?[i];
//   ^^
// [diag.deadCode] Dead code.
  print('reached');
}
''');
  }

  test_nullAwareIndexedWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null n, int i, int j) {
  n?[i] = j;
//   ^^^^^^
// [diag.deadCode] Dead code.
  print('reached');
}
''');
  }

  test_nullAwareMethodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null n, int i) {
  n?.foo(i);
//   ^^^^^^
// [diag.deadCode] Dead code.
  print('reached');
}
''');
  }

  test_nullAwarePropertyRead() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null n) {
  n?.p;
//   ^
// [diag.deadCode] Dead code.
  print('reached');
}
''');
  }

  test_nullAwarePropertyWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null n, int i) {
  n?.p = i;
//   ^^^^^
// [diag.deadCode] Dead code.
  print('reached');
}
''');
  }

  test_objectPattern_neverTypedGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Never get foo => throw 0;
}

void f(Object x) {
  if (x case A(foo: _)) {}
//                      ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_prefixedIdentifier_identifier() async {
    await resolveTestCodeWithDiagnostics(r'''
Never get doNotReturn => throw 0;

test() => doNotReturn.hashCode;
//                    ^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_propertyAccess_property() async {
    await resolveTestCodeWithDiagnostics(r'''
Never doNotReturn() => throw 0;

test() => doNotReturn().hashCode;
//                      ^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }
}

@reflectiveTest
class DeadCodeTest_AnonymousMethodsExperiment extends PubPackageResolutionTest {
  @override
  List<String> get experiments => ['anonymous-methods'];

  test_cascaded_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  never..=> 1;
//     ^^^^^^^
// [diag.deadCode] Dead code.
}

Never get never => throw 0;
''');
  }

  test_nullaware_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  null?.=> 1;
//    ^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_nullawareCascaded_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  null?..=> 1;
//    ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_parameterized_cascaded_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  never..(_) => 1;
//     ^^^^^^^^^^^
// [diag.deadCode] Dead code.
}

Never get never => throw 0;
''');
  }

  test_parameterized_nullaware_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  null?.(_) => 1;
//    ^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_parameterized_nullawareCascaded_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  null?..(_) => 1;
//    ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_parameterized_plain_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  never.(_) => 1;
//     ^^^^^^^^^^
// [diag.deadCode] Dead code.
}

Never get never => throw 0;
''');
  }

  test_plain_deadCode() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  never.=> 1;
//     ^^^^^^
// [diag.deadCode] Dead code.
}

Never get never => throw 0;
''');
  }
}

@reflectiveTest
class DeadCodeTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin, DeadCodeTestCases_Language212 {
  @override
  test_lateWildCardVariable_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  return;
  assert (true);
//^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_assert_dead_message() async {
    // We don't warn if an assert statement is live but its message is dead,
    // because this results in nuisance warnings for desirable assertions (e.g.
    // a `!= null` assertion that is redundant with strong checking but still
    // useful with weak checking).
    await resolveTestCodeWithDiagnostics('''
void f(Object waldo) {
  assert(waldo != null, "Where's Waldo?");
//             ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullTrue] The operand can't be 'null', so the condition is always 'true'.
}
''');
  }

  test_assigned_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i = 1;
  i?.truncate();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_class_field_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await resolveTestCodeWithDiagnostics('''
Never f() { throw ''; }

class C {
  static final x = [1, 2, f(), 4];
//                             ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_constructorInitializerWithThrow_thenBlockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A() : x = throw 0 {
// [diag.deadCode][column 21][length 12] Dead code.
    x;
  }
}
''');
  }

  test_constructorInitializerWithThrow_thenEmptyBlockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A() : x = throw 0 {}
}
''');
  }

  test_constructorInitializerWithThrow_thenEmptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A() : x = throw 0;
}
''');
  }

  test_constructorInitializerWithThrow_thenExpressions() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var x = [8];
  A() : x = [7, throw 8, 9];
//                       ^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_constructorInitializerWithThrow_thenInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  int y;
  A()
      : x = throw 0,
        y = 7;
//      ^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_continueInSwitch() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
f() {
  true ? 1 : 2;
//           ^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_conditionalElse_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}
''');
  }

  test_deadBlock_conditionalElse_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  true ? true : false && false;
//              ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_conditionalThen() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  false ? 1 : 2;
//        ^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_conditionalThen_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}
''');
  }

  test_deadBlock_conditionalThen_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  false ? false && false : true;
//        ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_else() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if(true) {} else {}
//                 ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_else_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}
''');
  }

  test_deadBlock_else_nested() async {
    // Test that a dead else-statement can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if(true) {} else {if (false) {}}
//                 ^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_if() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if(false) {}
//          ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_if_debugConst_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}
''');
  }

  test_deadBlock_if_debugConst_simpleIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}
''');
  }

  test_deadBlock_if_nested() async {
    // Test that a dead then-statement can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if(false) {if(false) {}}
//          ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_ifElement() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  [
    if (false) 2,
//             ^
// [diag.deadCode] Dead code.
  ];
}
''');
  }

  test_deadBlock_ifElement_else() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  [
    if (true) 2
    else 3,
//       ^
// [diag.deadCode] Dead code.
  ];
}
''');
  }

  test_deadBlock_while() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  while(false) {}
//             ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadBlock_while_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}
''');
  }

  test_deadBlock_while_nested() async {
    // Test that a dead while body can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  while(false) {if(false) {}}
//             ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_deadCatch_catchFollowingCatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
//                    ^^^^^^^^^^^^
// [diag.deadCodeCatchFollowingCatch] Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached.
}
''');
  }

  test_deadCatch_catchFollowingCatch_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
//                    ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCodeCatchFollowingCatch] Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached.
}
''');
  }

  test_deadCatch_catchFollowingCatch_object() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
//                        ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
//                              ^^^^^^^^^^^^
// [diag.deadCodeCatchFollowingCatch] Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached.
}
''');
  }

  test_deadCatch_catchFollowingCatch_object_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
//                        ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
//                              ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCodeCatchFollowingCatch] Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached.
}
''');
  }

  test_deadCatch_onCatchSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
//                   ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
//                         ^^^^^^^^^^^^^^^^^
// [diag.deadCodeOnCatchSubtype] Dead code: This on-catch block won't be executed because 'B' is a subtype of 'A' and hence will have been caught already.
//                                     ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
}
''');
  }

  test_deadCatch_onCatchSubtype_nested() async {
    // Test that a dead catch clause can't generate additional violations.
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
//                   ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
//                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCodeOnCatchSubtype] Dead code: This on-catch block won't be executed because 'B' is a subtype of 'A' and hence will have been caught already.
//                                     ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
}
''');
  }

  test_deadCatch_onCatchSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
//                   ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
//                                     ^
// [diag.unusedCatchClause] The exception variable 'e' isn't used, so the 'catch' clause can be removed.
}
''');
  }

  test_deadOperandLHS_and() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  bool b = false && false;
//               ^^^^^^^^
// [diag.deadCode] Dead code.
  print(b);
}
''');
  }

  test_deadOperandLHS_and_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
  print(b);
}
''');
  }

  test_deadOperandLHS_and_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  bool b = false && (false && false);
//               ^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print(b);
}
''');
  }

  test_deadOperandLHS_or() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  bool b = true || true;
//              ^^^^^^^
// [diag.deadCode] Dead code.
  print(b);
}
''');
  }

  test_deadOperandLHS_or_debugConst() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
  }

  test_deadOperandLHS_or_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  bool b = true || (false && false);
//              ^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print(b);
}
''');
  }

  test_documentationComment() async {
    await resolveTestCodeWithDiagnostics(r'''
/// text
int f() => 0;
''');
  }

  test_doWhile() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_doWhile_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  do {
    if (c) {
     break;
    }
    return;
  } while (c);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print('');
}
''');
  }

  test_doWhile_break_doLabel() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  label:
  do {
    if (c) {
      break label;
    }
    return;
  } while (c);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print('');
}
''');
  }

  test_doWhile_break_inner() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  do {
    while (c) {
      break;
    }
    return;
  } while (c);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print('');
//^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  Future<void> test_doWhile_break_outerDoLabel() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  label:
  do {
    do {
      if (c) {
        break label;
      }
      return;
    } while (c);
//  ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
    print('');
// [diag.deadCode][column 5][length 38] Dead code.
  } while (c);
  print('');
}
''');
  }

  Future<void> test_doWhile_break_outerLabel() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  label: {
    do {
      if (c) {
       break label;
      }
      return;
    } while (c);
//  ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
    print('');
// [diag.deadCode][column 5][length 14] Dead code.
  }
}
''');
  }

  test_doWhile_statements() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  do {
    print(c);
    return;
  } while (c);
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  print('2');
//^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_block_forStatement_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;; 1) {
//        ^
// [diag.deadCode] Dead code.
    return;
    2;
//  ^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_flowEnd_block_forStatement_updaters_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;; 1, 2) {
//        ^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forElementParts_condition_exists() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (; throw 0; 1) 0];
//                      ^
// [diag.deadCode] Dead code.
//                         ^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_condition_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool Function(Object?, Object?) g) => [for (; g(throw 0, 1); 2) 0];
//                                                         ^^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_initializer_declaration_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = throw 0; true; 1) 0];
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                            ^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_initializer_expression_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (throw 0; true; 1) 0];
//                    ^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_assignmentExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i = i + 1) throw ''];
//                       ^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i + 1) throw ''];
//                       ^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_cascadeExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i..sign) throw ''];
//                       ^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_conditionalExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i > 1 ? i : i) throw ''];
//                       ^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int> values) => [for (;; values[0]) throw ''];
//                              ^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_instanceCreationExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
f() => [for (;; C()) throw ''];
//              ^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i.toString()) throw ''];
//                       ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_postfixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; i++) throw ''];
//                       ^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as m;

f() => [for (;; m.Point) throw ''];
//              ^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; ++i) throw ''];
//                       ^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (var i = 0;; (i).sign) throw ''];
//                       ^^^^^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forElementParts_updaters_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (;; 0, throw 1, 2) 0];
//                          ^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_forParts_condition_exists() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (; throw 0; 1) {}
//                ^
// [diag.deadCode] Dead code.
//                   ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_forParts_condition_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool Function(Object?, Object?) g) {
  for (; g(throw 0, 1); 2) {}
//                  ^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_forParts_initializer_declaration_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = throw 0; true; 1) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                      ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_forParts_initializer_expression_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (throw 0; true; 1) {}
//              ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_forParts_updaters_assignmentExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i = i + 1) {
//                 ^^^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i + 1) {
//                 ^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_cascadeExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i..sign) {
//                 ^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_conditionalExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i > 1 ? i : i) {
//                 ^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<int> values) {
  for (;; values[0]) {
//        ^^^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_instanceCreationExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
void f() {
  for (;; C()) {
//        ^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i.toString()) {
//                 ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_postfixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; i++) {
//                 ^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_prefixedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as m;

void f() {
  for (;; m.Point) {
//        ^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; ++i) {
//                 ^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0;; (i).sign) {
//                 ^^^^^^^^
// [diag.deadCode] Dead code.
    return;
  }
}
''');
  }

  test_flowEnd_forParts_updaters_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;; 0, throw 1, 2) {}
//                    ^
// [diag.deadCode] Dead code.
}
''');
  }

  test_flowEnd_forStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  for (var v in [0, 1, 2]) {
    v;
    return;
    1;
//  ^^
// [diag.deadCode] Dead code.
  }
  2;
}
''');
  }

  test_flowEnd_ifStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool a) {
  if (a) {
    return;
    1;
//  ^^
// [diag.deadCode] Dead code.
  }
  2;
}
''');
  }

  test_flowEnd_list_forElement_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (;; 1) ...[throw '', 2]];
//              ^
// [diag.deadCode] Dead code.
//                               ^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_list_forElement_updaters_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => [for (;; 1, 2) ...[throw '']];
//              ^^^^
// [diag.deadCode] Dead code.
''');
  }

  test_flowEnd_nestedBlock_forStatement_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;; 1) {
//        ^
// [diag.deadCode] Dead code.
    {
      return;
      2;
// [diag.deadCode][column 7][length 8] Dead code.
    }
  }
}
''');
  }

  test_flowEnd_nestedBlock_forStatement_updaters_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (;; 1, 2) {
//        ^^^^
// [diag.deadCode] Dead code.
    {
      return;
    }
  }
}
''');
  }

  test_flowEnd_tryStatement_body() async {
    await resolveTestCodeWithDiagnostics(r'''
Never foo() => throw 0;

main() {
  try {
    foo();
    1;
//  ^^
// [diag.deadCode] Dead code.
  } catch (_) {
    2;
  }
  3;
}
''');
  }

  test_flowEnd_tryStatement_catchClause() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  try {
    1;
  } catch (_) {
    return;
    2;
//  ^^
// [diag.deadCode] Dead code.
  }
  3;
}
''');
  }

  test_flowEnd_tryStatement_finally() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  try {
    1;
  } finally {
    2;
    return;
    3;
// [diag.deadCode][column 5][length 11] Dead code.
  }
  4;
}
''');
  }

  test_forStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  return;
  for (;;) {}
//^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_ifStatement_noCase_conditionFalse() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  if (false) {
// [diag.deadCode][column 14][length 12] Dead code.
    1;
  } else {
    2;
  }
  3;
}
''');
  }

  test_ifStatement_noCase_conditionTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  if (true) {
    1;
  } else {
// [diag.deadCode][column 10][length 12] Dead code.
    2;
  }
  3;
}
''');
  }

  test_invokeNever_functionExpressionInvocation_getter_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Never get f => throw 0;
}
void g(A a) {
  a.f(0);
//^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
// [diag.deadCode][column 6][length 16] Dead code.
  print(1);
}
''');
  }

  test_invokeNever_functionExpressionInvocation_parenthesizedExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Never f) {
  (f)(0);
//^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
// [diag.deadCode][column 6][length 16] Dead code.
  print(1);
}
''');
  }

  test_invokeNever_functionExpressionInvocation_simpleIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Never f) {
  f(0);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
// [diag.deadCode][column 4][length 16] Dead code.
  print(1);
}
''');
  }

  test_lateWildCardVariable_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  late var _ = 0;
//             ^
// [diag.deadCodeLateWildcardVariableInitializer] Dead code: The assigned-to wildcard variable is marked late and can never be referenced so this initializer will never be evaluated.
}
''');
  }

  test_lateWildCardVariable_noInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  late var _;
}
''');
  }

  test_notUnassigned_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? i) {
  (i)?.sign;
}
''');
  }

  test_potentiallyAssigned_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
Never foo() => throw 0;

main() {
  foo();
  1;
//^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_returnTypeNever_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
Never get foo => throw 0;

main() {
  foo;
  2;
//^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_statementAfterAlwaysThrowsGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
// ^^^^^^^^^^^^
// [diag.deprecatedMemberUseWithMessage] 'alwaysThrows' is deprecated and shouldn't be used. Use a return type of 'Never' instead.
  int get a {
    throw 'msg';
  }
}

f() {
  print(1);
  new C().a;
  print(2);
}
''');
  }

  test_statementAfterBreak_inDefaultCase() async {
    await resolveTestCodeWithDiagnostics(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      print(1);
//    ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterBreak_inForEachStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var list;
  for(var l in list) {
    break;
    print(l);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterBreak_inForStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for(;;) {
    break;
    print(1);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterBreak_inSwitchCase() async {
    await resolveTestCodeWithDiagnostics(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      print(1);
//    ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterBreak_inWhileStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f(v) {
  while(v) {
    break;
    print(1);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterContinue_inForEachStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    print(l);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterContinue_inForStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for(;;) {
    continue;
    print(1);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterContinue_inWhileStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f(v) {
  while(v) {
    continue;
    print(1);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterExitingIf_returns() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  print(1);
//^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_statementAfterIfWithoutElse() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if (1 < 0) {
    return;
  }
  print(1);
}
''');
  }

  test_statementAfterRethrow() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
    print(1);
  } catch (e) {
    rethrow;
    print(2);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterReturn_function() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  print(1);
  return;
  print(2);
//^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_statementAfterReturn_function_local() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  void g() {
    print(1);
    return;
    print(2);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
  g();
}
''');
  }

  test_statementAfterReturn_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  () {
    print(1);
    return;
    print(2);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  };
}
''');
  }

  test_statementAfterReturn_ifStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool b) {
  if(b) {
    print(1);
    return;
    print(2);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterReturn_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {
    print(1);
    return;
    print(2);
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_statementAfterReturn_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  print(1);
  return;
  if(false) {}
//^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_statementAfterReturn_twoReturns() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  print(1);
  return;
  print(2);
// [diag.deadCode][column 3][length 31] Dead code.
  return;
  print(3);
}
''');
  }

  test_statementAfterThrow() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  print(1);
  throw 'Stop here';
  print(2);
//^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_switchCase_final_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      break;
//    ^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_switchCase_final_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  for (var i = 0; i < 2; i++) {
    switch (a) {
      case 0:
        try {} finally {
          return;
        }
        continue;
//      ^^^^^^^^^
// [diag.deadCode] Dead code.
    }
  }
}
''');
  }

  test_switchCase_final_rethrow() async {
    await resolveTestCodeWithDiagnostics(r'''
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
//      ^^^^^^^^
// [diag.deadCode] Dead code.
    }
  }
}
''');
  }

  test_switchCase_final_return() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      return;
//    ^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_switchCase_final_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  switch (a) {
    case 0:
      try {} finally {
        return;
      }
      throw 0;
//    ^^^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }

  test_switchStatement_exhaustive() async {
    await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a: return 0;
    case Foo.b: return 1;
  }
  return -1;
//^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_topLevelVariable_initializer_listLiteral() async {
    // Based on https://github.com/dart-lang/sdk/issues/49701
    await resolveTestCodeWithDiagnostics('''
Never f() { throw ''; }

var x = [1, 2, f(), 4];
//                  ^^
// [diag.deadCode] Dead code.
''');
  }

  test_try_finally() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  try {
    foo();
    print('dead');
//  ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
  } finally {
    print('alive');
  }
  print('dead');
//^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
Never foo() => throw 'exception';
''');
  }

  test_unassigned_cascadeExpression_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<int>? l;
  l?..[0]..length;
// ^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_cascadeExpression_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  i?..toInt()..isEven;
// ^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_cascadeExpression_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  i?..sign..isEven;
// ^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<int>? l;
  l?[0];
// ^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_indexExpression_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<List<int>>? l;
  l?[0][0];
// ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  i?.truncate();
// ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_methodInvocation_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  i?.truncate().truncate();
// ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_methodInvocation_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  i?.truncate().sign;
// ^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  (i)?.sign;
//   ^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_unassigned_propertyAccess_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int? i;
  (i)?.sign.sign;
//   ^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_yield() async {
    await resolveTestCodeWithDiagnostics(r'''
Iterable<int> f() sync* {
  return;
  yield 1;
//^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }
}
