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
    defineReflectiveTests(MapLiteralTest);
    defineReflectiveTests(MapLiteralWithFlowControlAndSpreadCollectionsTest);
  });
}

@reflectiveTest
class MapLiteralTest extends DriverResolutionTest {
  AstNode mapLiteral(String search) => findNode.mapLiteral(search);

  test_context_noTypeArgs_entry_conflict() async {
    addTestFile('''
Map<int, int> a = {'a' : 1};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    addTestFile('''
Map<int, int> a = {1 : 2};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_noEntries() async {
    addTestFile('''
Map<String, String> a = {};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflict() async {
    addTestFile('''
Map<String, String> a = <String, String>{0 : 'a'};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    addTestFile('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    addTestFile('''
Map<String, String> a = <int, int>{};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    addTestFile('''
Map<String, String> a = <String, String>{};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<String, String>');
  }

  test_noContext_noTypeArgs_expressions_conflict() async {
    addTestFile('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_expressions_noConflict() async {
    addTestFile('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    addTestFile('''
var a = {};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_typeArgs_entry_conflict() async {
    addTestFile('''
var a = <String, int>{'a' : 1};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    addTestFile('''
var a = <int, int>{1 : 2};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    addTestFile('''
var a = <num, String>{};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<num, String>');
  }
}

@reflectiveTest
class MapLiteralWithFlowControlAndSpreadCollectionsTest extends MapLiteralTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  @override
  AstNode mapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    addTestFile('''
var c = [1, 2, 3];
var a = {for (int e in c) e : e * 2};
''');
    await resolveTestFile();
    assertType(mapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    addTestFile('''
var c = [1, 2, 3];
int b;
var a = {for (b in c) b * 2 : b};
''');
    await resolveTestFile();
    assertType(mapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    addTestFile('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    await resolveTestFile();
    assertType(mapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    addTestFile('''
int i;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    await resolveTestFile();
    assertType(mapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    addTestFile('''
var c = true;
var a = {if (c) 1 : 2};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_conflict() async {
    addTestFile('''
var c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_ifElse_noConflict() async {
    addTestFile('''
var c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    await resolveTestFile();
    assertType(mapLiteral('{'), 'Map<int, int>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread() async {
    addTestFile('''
var c = {1 : 1, 2 : 2, 3 : 3};
var a = {...c};
''');
    await resolveTestFile();
    assertType(mapLiteral('{...'), 'Map<int, int>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread_conflict() async {
    addTestFile('''
var c = {1 : 2};
var b = {'a' : 'b'};
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(mapLiteral('{...'), 'Map<Object, Object>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread_noConflict() async {
    addTestFile('''
var c = {1 : 3};
var b = {2 : 4};
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(mapLiteral('{...'), 'Map<int, int>');
  }
}
