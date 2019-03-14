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

  test_context_noTypeArgs_noElements_typeParameter() async {
    addTestFile('''
class A<E extends Set<int>> {
  E a = {};
}
''');
    await resolveTestFile();
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    addTestFile('''
class A<E extends Set<dynamic>> {
  E a = {};
}
''');
    await resolveTestFile();
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    addTestFile('''
Set<String> a = <String>{0};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    addTestFile('''
Set<String> a = <int>{'a'};
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

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    addTestFile('''
var a = {1, 2, 3};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    addTestFile('''
var a = {1, 2.3, 4};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    addTestFile('''
var a = {1, '2', 3};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<Object>');
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

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    addTestFile('''
var a = <int, String>{1, 2};
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
List<int> c;
var a = {for (int e in c) e * 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    addTestFile('''
List<int> c;
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
bool c = true;
var a = {if (c) 1};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 else 2};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 else 2.3};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 else '2'};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread() async {
    addTestFile('''
List<int> c;
var a = {...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    addTestFile('''
List<int> c;
List<int> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    addTestFile('''
List<int> c;
List<double> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    addTestFile('''
List<int> c;
List<String> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setLiteral('{...'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    addTestFile('''
List<int> c;
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    await resolveTestFile();
    assertType(setLiteral('{'), 'Set<dynamic>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    addTestFile('''
f() {
  var futureNull = Future.value(null);
  var a = {1, ...?await futureNull, 2};
}
''');
    await resolveTestFile();
    assertType(setLiteral('{1'), 'Set<int>');
  }
}
