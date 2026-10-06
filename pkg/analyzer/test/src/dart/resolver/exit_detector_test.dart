// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart' show ToBeDeprecated;
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExitDetector2CollectionElementTest);
    defineReflectiveTests(ExitDetector2ResolvedStatementTest);
    defineReflectiveTests(ExitDetector2ResolvedStatementTest_BeforePatterns);
    defineReflectiveTests(ExitDetector2StatementTest);
    // ignore: analyzer_to_be_deprecated_use
    defineReflectiveTests(ExitDetectorCollectionElementTest);
    // ignore: analyzer_to_be_deprecated_use
    defineReflectiveTests(ExitDetectorParsedStatementTest);
    // ignore: analyzer_to_be_deprecated_use
    defineReflectiveTests(ExitDetectorResolvedStatementTest);
    // ignore: analyzer_to_be_deprecated_use
    defineReflectiveTests(ExitDetectorResolvedStatementTest_BeforePatterns);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExitDetector2CollectionElementTest extends PubPackageResolutionTest
    with ExitDetectorCollectionElementTestCases {
  @override
  Future<void> _assertHasReturn(String expressionCode, bool expected) async {
    var result = await resolveTestCode('''
void f() { // ref
  $expressionCode;
}
''');
    var block = result.findNode.block('{ // ref');
    var statement = block.statements.single as ExpressionStatement;
    expect(ExitDetector2.exits(statement.expression2), expected);
  }
}

@reflectiveTest
class ExitDetector2ResolvedStatementTest extends PubPackageResolutionTest
    with ExitDetectorStatementWithResolutionTestCases {
  @override
  bool _exits(Statement statement) => ExitDetector2.exits(statement);
}

@reflectiveTest
class ExitDetector2ResolvedStatementTest_BeforePatterns
    extends PubPackageResolutionTest
    with BeforePatternsMixin, ExitDetectorStatementWithResolutionTestCases {
  @override
  bool _exits(Statement statement) => ExitDetector2.exits(statement);
}

@reflectiveTest
class ExitDetector2StatementTest extends PubPackageResolutionTest
    with ExitDetectorStatementTestCases {
  @override
  Future<void> _assertHasReturn(String statementCode, bool expected) async {
    var result = await resolveTestCode('''
void f() { // ref
  $statementCode
}
''');
    var block = result.findNode.block('{ // ref');
    var statement = block.statements.single;
    expect(ExitDetector2.exits(statement), expected);
  }
}

@reflectiveTest
@ToBeDeprecated('Use ExitDetector2 tests instead.')
class ExitDetectorCollectionElementTest extends ParserDiagnosticsTest
    with ExitDetectorCollectionElementTestCases {
  @override
  Future<void> _assertHasReturn(String expressionCode, bool expected) async {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() { // ref
  $expressionCode;
}
''');
    var block = parseResult.findNode.block('{ // ref');
    var statement = block.statements.single as ExpressionStatement;
    expect(ExitDetector.exits(statement.expression), expected);
  }
}

/// Tests for exit detectors with collection elements: `for` elements, `if`
/// elements, and null-aware elements.
mixin ExitDetectorCollectionElementTestCases {
  test_for_condition() async {
    await _assertTrue('[for (; throw 0;) 0]');
  }

  test_for_implicitTrue() async {
    await _assertTrue('[for (;;) 0]');
  }

  test_for_initialization() async {
    await _assertTrue('[for (i = throw 0;;) 0]');
  }

  test_for_true() async {
    await _assertTrue('[for (; true; ) 0]');
  }

  test_for_true_if_return() async {
    await _assertTrue('[for (; true; ) if (true) throw 42]');
  }

  test_for_true_noBreak() async {
    await _assertTrue('[for (; true; ) 0]');
  }

  test_for_updaters() async {
    await _assertTrue('[for (;; i++, throw 0) 1]');
  }

  test_for_variableDeclaration() async {
    await _assertTrue('[for (int i = throw 0;;) 1]');
  }

  test_forEach() async {
    await _assertFalse('[for (element in list) 0]');
  }

  test_forEach_throw() async {
    await _assertTrue('[for (element in throw 42) 0]');
  }

  test_if_false_else_throw() async {
    await _assertTrue('[if (false) 0 else throw 42]');
  }

  test_if_false_noThrow() async {
    await _assertFalse('[if (false) 0]');
  }

  test_if_false_throw() async {
    await _assertFalse('[if (false) throw 42]');
  }

  test_if_noThrow() async {
    await _assertFalse('[if (c) i++]');
  }

  test_if_throw() async {
    await _assertFalse('[if (c) throw 42]');
  }

  test_if_true_noThrow() async {
    await _assertFalse('[if (true) 0]');
  }

  test_if_true_throw() async {
    await _assertTrue('[if (true) throw 42]');
  }

  test_ifElse_bothThrow() async {
    await _assertTrue("[if (c) throw 0 else throw 1]");
  }

  test_ifElse_elseThrow() async {
    await _assertFalse('[if (c) 0 else throw 42]');
  }

  test_ifElse_noThrow() async {
    await _assertFalse('[if (c) 0 else 1]');
  }

  test_ifElse_thenThrow() async {
    await _assertFalse('[if (c) throw 42 else 0]');
  }

  test_nullAwareElement() async {
    await _assertFalse('[?0]');
  }

  Future<void> _assertFalse(String expressionCode) async {
    await _assertHasReturn(expressionCode, false);
  }

  /// Asserts whether the expression statement [expressionCode] in a function
  /// body exits.
  Future<void> _assertHasReturn(String expressionCode, bool expected);

  Future<void> _assertTrue(String expressionCode) async {
    await _assertHasReturn(expressionCode, true);
  }
}

@reflectiveTest
@ToBeDeprecated('Use ExitDetector2 tests instead.')
class ExitDetectorParsedStatementTest extends ParserDiagnosticsTest
    with ExitDetectorStatementTestCases {
  @failingTest
  @override
  test_assignmentExpression_compound_lazy() async {
    await super.test_assignmentExpression_compound_lazy();
  }

  @failingTest
  @override
  test_cascadeExpression_nullAware_index() async {
    await super.test_cascadeExpression_nullAware_index();
  }

  test_nullAssertion_v1Projection() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) { // ref
  x!;
}
''');
    var block = parseResult.findNode.block('{ // ref');
    var statement = block.statements.single as ExpressionStatement;

    var expression = statement.expression;

    expect(expression, isA<PostfixExpression>());
    expect(ExitDetector.exits(expression), isFalse);
  }

  @override
  Future<void> _assertHasReturn(String statementCode, bool expected) async {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() { // ref
  $statementCode
}
''');
    var block = parseResult.findNode.block('{ // ref');
    var statement = block.statements.single;
    expect(ExitDetector.exits(statement), expected);
  }
}

@reflectiveTest
@ToBeDeprecated('Use ExitDetector2 tests instead.')
class ExitDetectorResolvedStatementTest extends PubPackageResolutionTest
    with ExitDetectorStatementWithResolutionTestCases {
  @override
  bool _exits(Statement statement) => ExitDetector.exits(statement);
}

@reflectiveTest
@ToBeDeprecated('Use ExitDetector2 tests instead.')
class ExitDetectorResolvedStatementTest_BeforePatterns
    extends PubPackageResolutionTest
    with BeforePatternsMixin, ExitDetectorStatementWithResolutionTestCases {
  @override
  bool _exits(Statement statement) => ExitDetector.exits(statement);
}

/// Tests for exit detectors with statements, that do not depend on resolution.
///
/// See [ExitDetectorStatementWithResolutionTestCases] for tests that depend on
/// resolution.
mixin ExitDetectorStatementTestCases {
  test_asExpression() async {
    await _assertFalse('a as Object;');
  }

  test_asExpression_throw() async {
    await _assertTrue('throw 42 as Object;');
  }

  test_assertStatement() async {
    await _assertFalse("assert(a);");
  }

  test_assertStatement_throw() async {
    await _assertFalse('assert((throw 0));');
  }

  test_assignmentExpression() async {
    await _assertFalse('v = 1;');
  }

  test_assignmentExpression_compound_lazy() async {
    await _assertFalse('v ||= false;');
  }

  test_assignmentExpression_lhs_throw() async {
    await _assertTrue('a[throw 42] = 0;');
  }

  test_assignmentExpression_rhs_throw() async {
    await _assertTrue('v = throw 42;');
  }

  test_await_false() async {
    await _assertFalse('await x;');
  }

  test_await_throw_true() async {
    await _assertTrue('bool b = await (throw 42 || true);');
  }

  test_binaryExpression_and() async {
    await _assertFalse('a && b;');
  }

  test_binaryExpression_and_lhs() async {
    await _assertTrue('throw 42 && b;');
  }

  test_binaryExpression_and_rhs() async {
    await _assertFalse('a && (throw 42);');
  }

  test_binaryExpression_and_rhs2() async {
    await _assertFalse('false && (throw 42);');
  }

  test_binaryExpression_and_rhs3() async {
    await _assertTrue('true && (throw 42);');
  }

  test_binaryExpression_ifNull() async {
    await _assertFalse('a ?? b;');
  }

  test_binaryExpression_ifNull_lhs() async {
    await _assertTrue('throw 42 ?? b;');
  }

  test_binaryExpression_ifNull_rhs() async {
    await _assertFalse('a ?? (throw 42);');
  }

  test_binaryExpression_ifNull_rhs2() async {
    await _assertFalse('null ?? (throw 42);');
  }

  test_binaryExpression_or() async {
    await _assertFalse('a || b;');
  }

  test_binaryExpression_or_lhs() async {
    await _assertTrue('throw 42 || b;');
  }

  test_binaryExpression_or_rhs() async {
    await _assertFalse('a || (throw 42);');
  }

  test_binaryExpression_or_rhs2() async {
    await _assertFalse('true || (throw 42);');
  }

  test_binaryExpression_or_rhs3() async {
    await _assertTrue('false || (throw 42);');
  }

  test_block_empty() async {
    await _assertFalse('{}');
  }

  test_block_noReturn() async {
    await _assertFalse('{ int i = 0; }');
  }

  test_block_return() async {
    await _assertTrue('{ return 0; }');
  }

  test_block_returnNotLast() async {
    await _assertTrue('{ return 0; throw 42; }');
  }

  test_block_throwNotLast() async {
    await _assertTrue('{ throw 0; x = null; }');
  }

  test_cascadeExpression_argument() async {
    await _assertTrue('a..b(throw 42);');
  }

  test_cascadeExpression_index() async {
    await _assertTrue('a..[throw 42];');
  }

  test_cascadeExpression_nullAware_argument() async {
    await _assertFalse('a?..b(throw 42);');
  }

  test_cascadeExpression_nullAware_argument_secondSection() async {
    await _assertFalse('a?..b(0)..c(throw 42);');
  }

  test_cascadeExpression_nullAware_assignment() async {
    await _assertFalse('a?..b = throw 42;');
  }

  test_cascadeExpression_nullAware_assignment_secondSection() async {
    await _assertFalse('a?..b = 0..c = throw 42;');
  }

  test_cascadeExpression_nullAware_index() async {
    await _assertFalse('a?..[throw 42];');
  }

  test_cascadeExpression_nullAware_target() async {
    await _assertTrue('(throw 42)?..b();');
  }

  test_cascadeExpression_target() async {
    await _assertTrue('throw a..b();');
  }

  test_conditional_ifElse_bothThrows() async {
    await _assertTrue('c ? throw 42 : throw 42;');
  }

  test_conditional_ifElse_elseThrows() async {
    await _assertFalse('c ? i : throw 42;');
  }

  test_conditional_ifElse_noThrow() async {
    await _assertFalse('c ? i : j;');
  }

  test_conditional_ifElse_thenThrow() async {
    await _assertFalse('c ? throw 42 : j;');
  }

  test_conditionalAccess() async {
    await _assertFalse('a?.b;');
  }

  test_conditionalAccess_lhs() async {
    await _assertTrue('(throw 42)?.b;');
  }

  test_conditionalAccessAssign() async {
    await _assertFalse('a?.b = c;');
  }

  test_conditionalAccessAssign_lhs() async {
    await _assertTrue('(throw 42)?.b = c;');
  }

  test_conditionalAccessAssign_rhs() async {
    await _assertFalse('a?.b = throw 42;');
  }

  test_conditionalAccessAssign_rhs2() async {
    await _assertFalse("null?.b = throw 42;");
  }

  test_conditionalAccessIfNullAssign() async {
    await _assertFalse('a?.b ??= c;');
  }

  test_conditionalAccessIfNullAssign_lhs() async {
    await _assertTrue('(throw 42)?.b ??= c;');
  }

  test_conditionalAccessIfNullAssign_rhs() async {
    await _assertFalse('a?.b ??= throw 42;');
  }

  test_conditionalAccessIfNullAssign_rhs2() async {
    await _assertFalse('null?.b ??= throw 42;');
  }

  test_conditionalCall() async {
    await _assertFalse('a?.b(c);');
  }

  test_conditionalCall_lhs() async {
    await _assertTrue('(throw 42)?.b(c);');
  }

  test_conditionalCall_rhs() async {
    await _assertFalse('a?.b(throw 42);');
  }

  test_conditionalCall_rhs2() async {
    await _assertFalse('null?.b(throw 42);');
  }

  test_constructorInvocation() async {
    await _assertFalse('new A(b);');
  }

  test_constructorInvocation_argumentThrows() async {
    await _assertTrue('new A(throw 42);');
  }

  test_doStatement_break_and_throw() async {
    await _assertFalse('''
{
  do {
    if (1 == 1) break;
    throw 42;
  } while (0 == 1);
}
''');
  }

  test_doStatement_continue_and_throw() async {
    await _assertFalse('''
{
  do {
    if (1 == 1) continue;
    throw 42;
  } while (0 == 1);
}
''');
  }

  test_doStatement_continueDoInSwitch_and_throw() async {
    await _assertFalse('''
{
  D: do {
    switch (1) {
      L: case 0: continue D;
      M: case 1: break;
    }
    throw 42;
  } while (0 == 1);
}''');
  }

  test_doStatement_continueInSwitch_and_throw() async {
    await _assertFalse('''
{
  do {
    switch (1) {
      L: case 0: continue;
      M: case 1: break;
    }
    throw 42;
  } while (0 == 1);
}''');
  }

  test_doStatement_return() async {
    await _assertTrue('{ do { return null; } while (1 == 2); }');
  }

  test_doStatement_throwCondition() async {
    await _assertTrue('{ do {} while (throw 42); }');
  }

  test_doStatement_true_break() async {
    await _assertFalse('{ do { break; } while (true); }');
  }

  test_doStatement_true_continue() async {
    await _assertTrue('{ do { continue; } while (true); }');
  }

  test_doStatement_true_continueWithLabel() async {
    await _assertTrue('{ x: do { continue x; } while (true); }');
  }

  test_doStatement_true_if_return() async {
    await _assertTrue('{ do { if (true) {return null;} } while (true); }');
  }

  test_doStatement_true_noBreak() async {
    await _assertTrue('{ do {} while (true); }');
  }

  test_doStatement_true_return() async {
    await _assertTrue('{ do { return null; } while (true);  }');
  }

  test_emptyStatement() async {
    await _assertFalse(';');
  }

  test_forEachStatement() async {
    await _assertFalse('for (element in list) {}');
  }

  test_forEachStatement_throw() async {
    await _assertTrue('for (element in throw 42) {}');
  }

  test_forStatement_condition() async {
    await _assertTrue('for (; throw 0;) {}');
  }

  test_forStatement_implicitTrue() async {
    await _assertTrue('for (;;) {}');
  }

  test_forStatement_implicitTrue_break() async {
    await _assertFalse('for (;;) { break; }');
  }

  test_forStatement_implicitTrue_if_break() async {
    await _assertFalse('''
{
  for (;;) {
    if (1==2) {
      var a = 1;
    } else {
      break;
    }
  }
}
''');
  }

  test_forStatement_initialization() async {
    await _assertTrue('for (i = throw 0;;) {}');
  }

  test_forStatement_true() async {
    await _assertTrue('for (; true; ) {}');
  }

  test_forStatement_true_break() async {
    await _assertFalse('{ for (; true; ) { break; } }');
  }

  test_forStatement_true_continue() async {
    await _assertTrue('{ for (; true; ) { continue; } }');
  }

  test_forStatement_true_if_return() async {
    await _assertTrue('{ for (; true; ) { if (true) {return null;} } }');
  }

  test_forStatement_true_noBreak() async {
    await _assertTrue('{ for (; true; ) {} }');
  }

  test_forStatement_updaters() async {
    await _assertTrue('for (;; i++, throw 0) {}');
  }

  test_forStatement_variableDeclaration() async {
    await _assertTrue('for (int i = throw 0;;) {}');
  }

  test_functionExpression() async {
    await _assertFalse('(){};');
  }

  test_functionExpression_bodyThrows() async {
    await _assertFalse('(int i) => throw 42;');
  }

  test_functionExpressionInvocation() async {
    await _assertFalse('f(g);');
  }

  test_functionExpressionInvocation_argumentThrows() async {
    await _assertTrue('f(throw 42);');
  }

  test_functionExpressionInvocation_targetThrows() async {
    await _assertTrue("(throw 42)(g);");
  }

  test_functionReference() async {
    await _assertFalse('a<int>;');
  }

  test_functionReference_method() async {
    await _assertFalse('(a).m<int>;');
  }

  test_functionReference_method_throw() async {
    await _assertTrue('(throw 42).m<int>;');
  }

  test_identifier_prefixedIdentifier() async {
    await _assertFalse('a.b;');
  }

  test_identifier_simpleIdentifier() async {
    await _assertFalse('a;');
  }

  test_if_false_else_return() async {
    await _assertTrue('if (false) {} else { return 0; }');
  }

  test_if_false_noReturn() async {
    await _assertFalse('if (false) {}');
  }

  test_if_false_return() async {
    await _assertFalse('if (false) { return 0; }');
  }

  test_if_noReturn() async {
    await _assertFalse('if (c) i++;');
  }

  test_if_return() async {
    await _assertFalse('if (c) return 0;');
  }

  test_if_true_noReturn() async {
    await _assertFalse('if (true) {}');
  }

  test_if_true_return() async {
    await _assertTrue('if (true) { return 0; }');
  }

  test_ifElse_bothReturn() async {
    await _assertTrue('if (c) return 0; else return 1;');
  }

  test_ifElse_elseReturn() async {
    await _assertFalse('if (c) i++; else return 1;');
  }

  test_ifElse_noReturn() async {
    await _assertFalse('if (c) i++; else j++;');
  }

  test_ifElse_thenReturn() async {
    await _assertFalse('if (c) return 0; else j++;');
  }

  test_ifNullAssign() async {
    await _assertFalse('a ??= b;');
  }

  test_ifNullAssign_rhs() async {
    await _assertFalse('a ??= throw 42;');
  }

  test_indexExpression() async {
    await _assertFalse('a[b];');
  }

  test_indexExpression_index() async {
    await _assertTrue('a[throw 42];');
  }

  test_indexExpression_target() async {
    await _assertTrue("(throw 42)[b];");
  }

  test_isExpression() async {
    await _assertFalse('A is B;');
  }

  test_isExpression_throws() async {
    await _assertTrue('throw 42 is B;');
  }

  test_labeledStatement() async {
    await _assertFalse('label: a;');
  }

  test_labeledStatement_throws() async {
    await _assertTrue('label: throw 42;');
  }

  test_literal_boolean() async {
    await _assertFalse('true;');
  }

  test_literal_double() async {
    await _assertFalse('1.1;');
  }

  test_literal_integer() async {
    await _assertFalse('1;');
  }

  test_literal_null() async {
    await _assertFalse('null;');
  }

  test_literal_String() async {
    await _assertFalse('"str";');
  }

  test_methodInvocation() async {
    await _assertFalse('a.b(c);');
  }

  test_methodInvocation_argument() async {
    await _assertTrue('a.b(throw 42);');
  }

  test_methodInvocation_target() async {
    await _assertTrue("(throw 42).b(c);");
  }

  test_nullAssertion() async {
    await _assertFalse('x!;');
  }

  test_parenthesizedExpression() async {
    await _assertFalse('(a);');
  }

  test_parenthesizedExpression_throw() async {
    await _assertTrue('(throw 42);');
  }

  test_propertyAccess() async {
    await _assertFalse('new Object().a;');
  }

  test_propertyAccess_throws() async {
    await _assertTrue('(throw 42).a;');
  }

  test_rethrow() async {
    await _assertTrue('rethrow;');
  }

  test_return() async {
    await _assertTrue('return 0;');
  }

  test_superExpression() async {
    await _assertFalse('super.a;');
  }

  test_switch_allReturn() async {
    await _assertTrue('switch (i) { case 0: return 0; default: return 1; }');
  }

  test_switch_defaultWithNoStatements() async {
    await _assertFalse('switch (i) { case 0: return 0; default: }');
  }

  test_switch_fallThroughToNotReturn() async {
    await _assertFalse(r'''
switch (i) {
  case 0:
  case 1:
    break;
  default:
    return 1;
}
''');
  }

  test_switch_fallThroughToReturn() async {
    await _assertTrue(r'''
switch (i) {
  case 0:
  case 1:
    return 0;
  default:
    return 1;
}
''');
  }

  @failingTest
  test_switch_includesContinue() async {
    await _assertTrue('''
switch (i) {
  zero: case 0: return 0;
  case 1: continue zero;
  default: return 1;
}''');
  }

  test_switch_noDefault() async {
    await _assertFalse('switch (i) { case 0: return 0; }');
  }

  // The ExitDetector could conceivably follow switch continue labels and
  // determine that `case 0` exits, `case 1` continues to an exiting case, and
  // `default` exits, so the switch exits.
  test_switch_nonReturn() async {
    await _assertFalse('switch (i) { case 0: i++; default: return 1; }');
  }

  test_switchExpression_allThrow() async {
    await _assertTrue('var x = switch (i) { 0 => throw 0, _ => throw 1, };');
  }

  test_switchExpression_notAllThrow() async {
    await _assertFalse('var x = switch (i) { 0 => 0, _ => throw 1, };');
  }

  test_switchExpression_throwInWhen() async {
    await _assertTrue('''
var x = switch (i) {
  0 when throw 7 => 0,
  _ => throw 1,
};
''');
  }

  test_thisExpression() async {
    await _assertFalse('this.a;');
  }

  test_throwExpression() async {
    await _assertTrue('throw new Object();');
  }

  test_tryStatement_noReturn() async {
    await _assertFalse('try {} catch (e, s) {} finally {}');
  }

  test_tryStatement_noReturn_noFinally() async {
    await _assertFalse('try {} catch (e, s) {}');
  }

  test_tryStatement_return_catch() async {
    await _assertFalse('try {} catch (e, s) { return 1; } finally {}');
  }

  test_tryStatement_return_catch_noFinally() async {
    await _assertFalse('try {} catch (e, s) { return 1; }');
  }

  test_tryStatement_return_finally() async {
    await _assertTrue('try {} catch (e, s) {} finally { return 1; }');
  }

  test_tryStatement_return_try_noCatch() async {
    await _assertTrue('try { return 1; } finally {}');
  }

  test_tryStatement_return_try_oneCatchDoesNotExit() async {
    await _assertFalse('try { return 1; } catch (e, s) {} finally {}');
  }

  test_tryStatement_return_try_oneCatchDoesNotExit_noFinally() async {
    await _assertFalse('try { return 1; } catch (e, s) {}');
  }

  test_tryStatement_return_try_oneCatchExits() async {
    await _assertTrue('''
try {
  return 1;
} catch (e, s) {
  return 1;
} finally {}
''');
  }

  test_tryStatement_return_try_oneCatchExits_noFinally() async {
    await _assertTrue('try { return 1; } catch (e, s) { return 1; }');
  }

  test_tryStatement_return_try_twoCatchesDoExit() async {
    await _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesDoExit_noFinally() async {
    await _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit() async {
    await _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit_noFinally() async {
    await _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
''');
  }

  test_tryStatement_return_try_twoCatchesMixed() async {
    await _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
finally {}
''');
  }

  test_tryStatement_return_try_twoCatchesMixed_noFinally() async {
    await _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
''');
  }

  test_variableDeclarationStatement_noInitializer() async {
    await _assertFalse('int i;');
  }

  test_variableDeclarationStatement_noThrow() async {
    await _assertFalse('int i = 0;');
  }

  test_variableDeclarationStatement_throw() async {
    await _assertTrue('int i = throw new Object();');
  }

  test_whileStatement_false_nonReturn() async {
    await _assertFalse("{ while (false) {} }");
  }

  test_whileStatement_throwCondition() async {
    await _assertTrue('{ while (throw 42) {} }');
  }

  test_whileStatement_true_break() async {
    await _assertFalse('{ while (true) { break; } }');
  }

  test_whileStatement_true_break_and_throw() async {
    await _assertFalse('{ while (true) { if (1==1) break; throw 42; } }');
  }

  test_whileStatement_true_continue() async {
    await _assertTrue('{ while (true) { continue; } }');
  }

  test_whileStatement_true_continueWithLabel() async {
    await _assertTrue('{ x: while (true) { continue x; } }');
  }

  test_whileStatement_true_doStatement_scopeRequired() async {
    await _assertTrue(
      '{ while (true) { x: do { continue x; } while (true); } }',
    );
  }

  test_whileStatement_true_if_return() async {
    await _assertTrue('{ while (true) { if (true) {return null;} } }');
  }

  test_whileStatement_true_noBreak() async {
    await _assertTrue('{ while (true) {} }');
  }

  test_whileStatement_true_return() async {
    await _assertTrue('{ while (true) { return null; } }');
  }

  test_whileStatement_true_throw() async {
    await _assertTrue('{ while (true) { throw 42; } }');
  }

  Future<void> _assertFalse(String code) async {
    await _assertHasReturn(code, false);
  }

  /// Asserts whether the statement [statementCode] in a function body exits.
  Future<void> _assertHasReturn(String statementCode, bool expected);

  Future<void> _assertTrue(String code) async {
    await _assertHasReturn(code, true);
  }
}

/// Tests for exit detectors with statements, that depend on resolution.
///
/// See [ExitDetectorStatementTestCases] for tests that do not depend on
/// resolution.
mixin ExitDetectorStatementWithResolutionTestCases on PubPackageResolutionTest {
  test_dotShorthandConstructorInvocation_namedArgumentThrows() async {
    await _assertNthStatementExits(r'''
class C {
  C({int? i});
}
void f() {
  C _ = .new(i: throw 42);
}
''', 0);
  }

  test_dotShorthandConstructorInvocation_noExit() async {
    await _assertNthStatementDoesNotExit(r'''
class C {
  C(int _);
}
void f() {
  C _ = .new(0);
}
''', 0);
  }

  test_dotShorthandConstructorInvocation_positionalArgumentThrows() async {
    await _assertNthStatementExits(r'''
class C {
  C(int _);
}
void f() {
  C _ = .new(throw 42);
}
''', 0);
  }

  test_dotShorthandInvocation_argumentThrows() async {
    await _assertNthStatementExits(r'''
class C {
  static C create(int _) => C();
}
void f() {
  C _ = .create(throw 42);
}
''', 0);
  }

  test_dotShorthandInvocation_methodReturnsNever() async {
    await _assertNthStatementExits(r'''
class C {
  static Never create() => throw 42;
}
void f() {
  C _ = .create();
}
''', 0);
  }

  test_dotShorthandInvocation_noExit() async {
    await _assertNthStatementDoesNotExit(r'''
class C {
  static C create(int _) => C();
}
void f() {
  C _ = .create(0);
}
''', 0);
  }

  test_dotShorthandPropertyAccess_getterReturnsNever() async {
    await _assertNthStatementExits(r'''
class C {
  static Never get foo => throw 42;
}
void f() {
  C _ = .foo;
}
''', 0);
  }

  test_dotShorthandPropertyAccess_noExit() async {
    await _assertNthStatementDoesNotExit(r'''
class C {
  static C get foo => C();
}
void f() {
  C _ = .foo;
}
''', 0);
  }

  test_forStatement_implicitTrue_breakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: for (;;) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''', 0);
  }

  test_patternAssignment() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
    final String s;
    (s: s) = (s: "");
}
    ''', 1);
  }

  test_patternVariableDeclaration() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
    final (s: s) = (s: "");
}
    ''', 0);
  }

  test_switch_withEnum_false_noDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    case B:
      x = 'B';
  }
  return x;
}
''', 1);
  }

  test_switch_withEnum_false_withDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    default:
      x = '?';
  }
  return x;
}
''', 1);
  }

  test_switch_withEnum_true_noDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    case B:
      return 'B';
  }
}
''', 0);
  }

  test_switch_withEnum_true_withExitingDefault() async {
    await _assertNthStatementExits(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    default:
      return '?';
  }
}
''', 0);
  }

  test_switch_withEnum_true_withNonExitingDefault() async {
    await _assertNthStatementDoesNotExit(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      return 'A';
    default:
      x = '?';
  }
}
''', 1);
  }

  test_whileStatement_breakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: while (true) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''', 0);
  }

  test_whileStatement_breakWithLabel_afterExiting() async {
    await _assertNthStatementExits(r'''
void f() {
  x: while (true) {
    return;
    if (1 < 2) {
      break x;
    }
  }
}
''', 0);
  }

  test_whileStatement_switchWithBreakWithLabel() async {
    await _assertNthStatementDoesNotExit(r'''
void f() {
  x: while (true) {
    switch (true) {
      case false: break;
      case true: break x;
    }
  }
}
''', 0);
  }

  test_yieldStatement_plain() async {
    await _assertNthStatementDoesNotExit(r'''
void f() sync* {
  yield 1;
}
''', 0);
  }

  test_yieldStatement_star_plain() async {
    await _assertNthStatementDoesNotExit(r'''
void f() sync* {
  yield* 1;
}
''', 0);
  }

  test_yieldStatement_star_throw() async {
    await _assertNthStatementExits(r'''
void f() sync* {
  yield* throw '';
}
''', 0);
  }

  test_yieldStatement_throw() async {
    await _assertNthStatementExits(r'''
void f() sync* {
  yield throw '';
}
''', 0);
  }

  Future<void> _assertHasReturn(String code, int n, bool expected) async {
    var result = await resolveTestCode(code);

    var function = result.unit.declarations2.last as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    Statement statement = body.block.statements[n];
    expect(_exits(statement), expected);
  }

  /// Assert that the [n]th statement in the last function declaration of
  /// [code] exits.
  Future<void> _assertNthStatementDoesNotExit(String code, int n) async {
    await _assertHasReturn(code, n, false);
  }

  /// Assert that the [n]th statement in the last function declaration of
  /// [code] does not exit.
  Future<void> _assertNthStatementExits(String code, int n) async {
    await _assertHasReturn(code, n, true);
  }

  /// Whether [statement] exits, according to the tested exit detector.
  bool _exits(Statement statement);
}
