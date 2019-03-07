// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest);
    defineReflectiveTests(ListLiteralWithFlowControlAndSpreadCollectionsTest);
  });
}

@reflectiveTest
class ListLiteralTest extends DriverResolutionTest {
  test_context_noTypeArgs_expression_conflict() async {
    addTestFile('''
List<int> a = ['a'];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    addTestFile('''
List<int> a = [1];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_noElements() async {
    addTestFile('''
List<String> a = [];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_conflict() async {
    addTestFile('''
List<String> a = <String>[0];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    addTestFile('''
List<String> a = <String>['a'];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    addTestFile('''
List<String> a = <int>[];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    addTestFile('''
List<String> a = <String>[];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_noTypeArgs_expressions_conflict() async {
    addTestFile('''
var a = [1, '2', 3];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_expressions_noConflict() async {
    addTestFile('''
var a = [1, 2, 3];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_noElements() async {
    addTestFile('''
var a = [];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    addTestFile('''
var a = <String>[1];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    addTestFile('''
var a = <int>[1];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_typeArgs_noElements() async {
    addTestFile('''
var a = <num>[];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<num>');
  }
}

@reflectiveTest
class ListLiteralWithFlowControlAndSpreadCollectionsTest
    extends ListLiteralTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    addTestFile('''
var c = [1, 2, 3];
var a = [for (int e in c) e * 2];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    addTestFile('''
var c = [1, 2, 3];
int b;
var a = [for (b in c) b * 2];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    addTestFile('''
var a = [for (var i = 0; i < 2; i++) i * 2];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    addTestFile('''
int i;
var a = [for (i = 0; i < 2; i++) i * 2];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_if() async {
    addTestFile('''
var c = true;
var a = [if (c) 1];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_conflict() async {
    addTestFile('''
var c = true;
var a = [if (c) 1 else '2'];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_ifElse_noConflict() async {
    addTestFile('''
var c = true;
var a = [if (c) 1 else 2];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_spread() async {
    addTestFile('''
var c = [1, 2, 3];
var a = [...c];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_conflict() async {
    addTestFile('''
var c = [1];
var b = ['a'];
var a = [...b, ...c];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[...'), 'List<Object>');
  }

  test_noContext_noTypeArgs_spread_noConflict() async {
    addTestFile('''
var c = [1];
var b = [2];
var a = [...b, ...c];
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_onlyNull() async {
    addTestFile('''
f() {
  var futureNull = Future.value(null);
  var a = [...?await futureNull];
}
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_nullAndNotNull() async {
    addTestFile('''
f() {
  var futureNull = Future.value(null);
  var a = [1, ...?await futureNull, 2];
}
''');
    await resolveTestFile();
    assertType(findNode.listLiteral('['), 'List<int>');
  }
}
