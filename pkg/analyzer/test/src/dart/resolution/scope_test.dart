// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnclosingNameScope2Test);
    // ignore: analyzer_v1_ast_use
    defineReflectiveTests(EnclosingNameScopeTest);
    defineReflectiveTests(PrefixedNamespaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class EnclosingNameScope2Test extends PubPackageResolutionTest
    with EnclosingNameScopeTestCases {
  @override
  void _assertNameScope(TestResolvedUnitResult result, String search) {
    var reference = result.findNode.unqualifiedNameExpression(search);
    var resolution = reference.resolution as NamedReadResolutionWithElement;
    var scope = reference.enclosingNameScope2!;
    expect(
      scope.lookup(reference.name.lexeme).getter,
      same(resolution.element),
    );
  }
}

@reflectiveTest
@V1Ast('The V2 counterpart is EnclosingNameScope2Test.')
class EnclosingNameScopeTest extends PubPackageResolutionTest
    with EnclosingNameScopeTestCases {
  @override
  void _assertNameScope(TestResolvedUnitResult result, String search) {
    var reference2 = result.findNode.unqualifiedNameExpression(search);
    var resolution = reference2.resolution as NamedReadResolutionWithElement;
    var reference = result.unit.nodeCovering(offset: reference2.offset)!;
    var scope = reference.enclosingNameScope!;
    expect(
      scope.lookup(reference2.name.lexeme).getter,
      same(resolution.element),
    );
  }
}

/// Each test resolves a reference to a local, and checks that the recorded
/// name scope at the reference agrees with resolution.
mixin EnclosingNameScopeTestCases on PubPackageResolutionTest {
  test_block_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 0;
  print(a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_block_localFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g() {}
  print(g);
}
''');
    _assertNameScope(result, 'g);');
  }

  test_block_localFunction_recursive() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g() {
    print(g);
  }
  g();
}
''');
    _assertNameScope(result, 'g);');
  }

  test_block_nested_outerLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 0;
  {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_block_nested_shadowingLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  {
    var a = 1;
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_catchClause_exceptionParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e) {
    print(e);
  }
}
''');
    _assertNameScope(result, 'e);');
  }

  test_catchClause_stackTraceParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e, s) {
    print(s);
  }
}
''');
    _assertNameScope(result, 's);');
  }

  test_forEachPartsWithDeclaration_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> list) {
  for (var e in list) print(e);
}
''');
    _assertNameScope(result, 'e);');
  }

  test_forEachPartsWithDeclaration_iterable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> e) {
  for (var e in e) print(e);
}
''');
    _assertNameScope(result, 'e) print');
  }

  test_forEachPartsWithPattern_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<(int, int)> list) {
  for (var (a, b) in list) print(a + b);
}
''');
    _assertNameScope(result, 'a +');
  }

  test_forEachPartsWithPattern_iterable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<(int, int)> a) {
  for (var (a, b) in a) print(a + b);
}
''');
    _assertNameScope(result, 'a) print');
  }

  test_forElement_forEachPartsWithDeclaration_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> list) {
  [for (var e in list) e];
}
''');
    _assertNameScope(result, 'e]');
  }

  test_forElement_forEachPartsWithDeclaration_iterable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> e) {
  [for (var e in e) e];
}
''');
    _assertNameScope(result, 'e) e');
  }

  test_forElement_forEachPartsWithPattern_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<(int, int)> list) {
  [for (var (a, b) in list) a + b];
}
''');
    _assertNameScope(result, 'a +');
  }

  test_forElement_forEachPartsWithPattern_iterable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<(int, int)> a) {
  [for (var (a, b) in a) a + b];
}
''');
    _assertNameScope(result, 'a) a');
  }

  test_forElement_forPartsWithDeclarations_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  [for (var i = 0; i < 1; i++) i];
}
''');
    _assertNameScope(result, 'i]');
  }

  test_forElement_forPartsWithPattern_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  [for (var (i, j) = (0, 1); i < j; i++) j];
}
''');
    _assertNameScope(result, 'j]');
  }

  test_formalParameter_constructor_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a) {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_formalParameter_localFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g(int a) {
    print(a);
  }
  g(0);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_formalParameter_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int a) {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_formalParameter_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  print(a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_formalParameter_topLevelSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int a) {
  print(a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_forPartsWithDeclarations_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0; i < 1; i++) print(i);
}
''');
    _assertNameScope(result, 'i);');
  }

  test_forPartsWithDeclarations_condition() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var i = 0; i < 1; i++) print(i);
}
''');
    _assertNameScope(result, 'i < 1');
  }

  test_forPartsWithPattern_body() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (i, j) = (0, 1); i < j; i++) print(j);
}
''');
    _assertNameScope(result, 'j);');
  }

  test_forPartsWithPattern_condition() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (i, j) = (0, 1); i < j; i++) print(j);
}
''');
    _assertNameScope(result, 'i < j');
  }

  test_functionExpression_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  print((int a) {
    print(a);
  });
}
''');
    _assertNameScope(result, 'a);');
  }

  test_functionExpression_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  print((int a) => a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifElement_caseClause_else() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o, int a) {
  [if (o case int a) 0 else a];
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    _assertNameScope(result, 'a]');
  }

  test_ifElement_caseClause_guard() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  [if (o case int a when a > 0) 0];
}
''');
    _assertNameScope(result, 'a >');
  }

  test_ifElement_caseClause_then() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  [if (o case int a) a];
}
''');
    _assertNameScope(result, 'a]');
  }

  test_ifElement_caseClause_then_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  [if (o case int a) a + 1];
}
''');
    _assertNameScope(result, 'a +');
  }

  test_ifStatement_caseClause_else() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o, int a) {
  if (o case int a) {
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  } else {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifStatement_caseClause_else_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) {
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  } else if (o case String a) {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifStatement_caseClause_else_ifCase_statement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) {
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  } else if (o case String a) print(a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifStatement_caseClause_guard() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a when a > 0) {}
}
''');
    _assertNameScope(result, 'a >');
  }

  test_ifStatement_caseClause_then_block() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) {
    print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifStatement_caseClause_then_functionExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) print(() => a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_ifStatement_caseClause_then_ifCase_inner() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) if (o case String b) print(a + b.length);
//                             ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'int' can never match the required type 'String'.
}
''');
    _assertNameScope(result, 'b.length');
  }

  test_ifStatement_caseClause_then_ifCase_outer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) if (o case String b) print(a + b.length);
//                             ^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'int' can never match the required type 'String'.
}
''');
    _assertNameScope(result, 'a +');
  }

  test_ifStatement_caseClause_then_statement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  if (o case int a) print(a);
}
''');
    _assertNameScope(result, 'a);');
  }

  test_patternVariableDeclarationStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, b) = (0, 1);
  print(a + b);
}
''');
    _assertNameScope(result, 'a +');
  }

  test_switchExpressionCase_expression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  print(switch (o) {
    int a => a,
    _ => 0,
  });
}
''');
    _assertNameScope(result, 'a,');
  }

  test_switchExpressionCase_guard() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  print(switch (o) {
    int a when a > 0 => 0,
    _ => 0,
  });
}
''');
    _assertNameScope(result, 'a >');
  }

  test_switchPatternCase_guard() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case int a when a > 0:
      break;
  }
}
''');
    _assertNameScope(result, 'a >');
  }

  test_switchPatternCase_sharedCase_default() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case int a:
    default:
      print(a);
//          ^
// [diag.patternVariableSharedCaseScopeHasLabel] The variable 'a' is not available because there is a label or 'default' case.
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_switchPatternCase_sharedCase_guard_first() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case [int a, int n] when n > 0:
    case {'a': int a}:
      print(a);
  }
}
''');
    _assertNameScope(result, 'n >');
  }

  test_switchPatternCase_sharedCase_guard_last() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case [int a]:
    case {'a': int a} when a > 0:
      print(a);
  }
}
''');
    _assertNameScope(result, 'a >');
  }

  test_switchPatternCase_sharedCase_statements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case [int a]:
    case {'a': int a}:
      print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  test_switchPatternCase_statements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case int a:
      print(a);
  }
}
''');
    _assertNameScope(result, 'a);');
  }

  /// Asserts that the name scope of the reference found by [search] looks up
  /// its name as the element that resolution bound the reference to.
  void _assertNameScope(TestResolvedUnitResult result, String search);
}

@reflectiveTest
class PrefixedNamespaceTest extends PubPackageResolutionTest {
  Future<({PrefixedNamespace namespace, TestResolvedUnitResult result})>
  get _dartMath async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
''');
    var namespace = result.findElement.import('dart:math').namespace;
    return (namespace: namespace as PrefixedNamespace, result: result);
  }

  void test_lookup_missing() async {
    var dartMath = await _dartMath;
    expect(dartMath.namespace.get2('prefix.Missing'), isNull);
  }

  Future<void> test_lookup_missing_matchesPrefix() async {
    var dartMath = await _dartMath;
    expect(dartMath.namespace.get2('prefix'), isNull);
  }

  Future<void> test_lookup_valid() async {
    var dartMath = await _dartMath;

    var random = dartMath.result.findElement
        .importFind('dart:math')
        .class_('Random');
    expect(dartMath.namespace.get2('prefix.Random'), same(random));
  }
}
