// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralTest);
    defineReflectiveTests(SetLiteralWithFlowControlAndSpreadCollectionsTest);
  });
}

@reflectiveTest
class SetLiteralTest extends DriverResolutionTest {
  AstNode setLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_expression_conflict() async {
    addTestFile('''
Set<int> a = {'a'};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    addTestFile('''
Set<int> a = {1};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements() async {
    addTestFile('''
Set<String> a = {};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  @FailingTest(
      issue: 'https://github.com/dart-lang/sdk/issues/35569',
      reason: 'Failing because Map<dynamic, dynamic> is being inferred.')
  test_context_noTypeArgs_noElements_typeParameter() async {
    addTestFile('''
class A<E extends Set<int>> {
  E a = {};
}
''');
    await resolveTestFile();
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_typeArgs_expression_conflict() async {
    addTestFile('''
Set<String> a = <String>{0};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    addTestFile('''
Set<String> a = <String>{'a'};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    addTestFile('''
Set<String> a = <int>{};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    addTestFile('''
Set<String> a = <String>{};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_noTypeArgs_expressions_conflict() async {
    addTestFile('''
var a = {1, '2', 3};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_expressions_noConflict() async {
    addTestFile('''
var a = {1, 2, 3};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    addTestFile('''
var a = <String>{1};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    addTestFile('''
var a = <int>{1};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_typeArgs_noElements() async {
    addTestFile('''
var a = <num>{};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<num>');
  }
}

@reflectiveTest
class SetLiteralWithFlowControlAndSpreadCollectionsTest extends SetLiteralTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  @override
  AstNode setLiteral(String search) => findNode.setOrMapLiteral(search);

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    addTestFile('''
var c = [1, 2, 3];
var a = {for (int e in c) e * 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    addTestFile('''
var c = [1, 2, 3];
int b;
var a = {for (b in c) b * 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    addTestFile('''
var a = {for (var i = 0; i < 2; i++) i * 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    addTestFile('''
int i;
var a = {for (i = 0; i < 2; i++) i * 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_if() async {
    addTestFile('''
var c = true;
var a = {if (c) 1};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_conflict() async {
    addTestFile('''
var c = true;
var a = {if (c) 1 else '2'};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_ifElse_noConflict() async {
    addTestFile('''
var c = true;
var a = {if (c) 1 else 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread() async {
    addTestFile('''
var c = [1, 2, 3];
var a = {...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_conflict() async {
    addTestFile('''
var c = [1];
var b = ['a'];
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread_noConflict() async {
    addTestFile('''
var c = [1];
var b = [2];
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<int>');
  }
}
