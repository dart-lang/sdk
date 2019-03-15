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
  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_entry_conflictingKey() async {
    addTestFile('''
Map<int, int> a = {'a' : 1};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_conflictingValue() async {
    addTestFile('''
Map<int, int> a = {1 : 'a'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    addTestFile('''
Map<int, int> a = {1 : 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_noEntries() async {
    addTestFile('''
Map<String, String> a = {};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_noTypeArgs_noEntries_typeParameters() async {
    addTestFile('''
class A<E extends Map<int, String>> {
  E a = {};
}
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_noTypeArgs_noEntries_typeParameters_dynamic() async {
    addTestFile('''
class A<E extends Map<dynamic, dynamic>> {
  E a = {};
}
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_typeArgs_entry_conflictingKey() async {
    addTestFile('''
Map<String, String> a = <String, String>{0 : 'a'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflictingValue() async {
    addTestFile('''
Map<String, String> a = <String, String>{'a' : 1};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    addTestFile('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    addTestFile('''
Map<String, String> a = <int, int>{};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    addTestFile('''
Map<String, String> a = <String, String>{};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_default_constructor_param_typed() async {
    addTestFile('''
class C {
  const C({x = const <String, int>{}});
}
''');
    await resolveTestFile();
  }

  test_default_constructor_param_untyped() async {
    addTestFile('''
class C {
  const C({x = const {}});
}
''');
    await resolveTestFile();
  }

  test_noContext_noTypeArgs_expressions_lubOfIntAndString() async {
    addTestFile('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNumAndNum() async {
    addTestFile('''
var a = {1 : 2, 3.0 : 4, 5 : 6.0};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObjectAndObject() async {
    addTestFile('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    addTestFile('''
var a = {};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_typeArgs_entry_conflictingKey() async {
    addTestFile('''
var a = <String, int>{1 : 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_conflictingValue() async {
    addTestFile('''
var a = <String, int>{'a' : 'b'};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    addTestFile('''
var a = <int, int>{1 : 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_expression_conflictingElement() async {
    addTestFile('''
var a = <int, String>{1};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflictingTypeArgs() async {
    addTestFile('''
var a = <int>{1 : 2, 3 : 4};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    addTestFile('''
var a = <num, String>{};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<num, String>');
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
  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    addTestFile('''
List<int> c;
var a = {for (int e in c) e : e * 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    addTestFile('''
List<int> c;
int b;
var a = {for (b in c) b * 2 : b};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    addTestFile('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    addTestFile('''
int i;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 : 2};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfIntAndInt() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNumAndNum() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1.0 : 3 else 2 : 4.0};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObjectAndObject() async {
    addTestFile('''
bool c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread() async {
    addTestFile('''
Map<int, int> c;
var a = {...c};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_dynamic() async {
    addTestFile('''
var c = {};
var a = {...c};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_lubOfIntAndInt() async {
    addTestFile('''
Map<int, int> c;
Map<int, int> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNumAndNum() async {
    addTestFile('''
Map<int, double> c;
Map<double, int> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObjectObject() async {
    addTestFile('''
Map<int, int> c;
Map<String, String> b;
var a = {...b, ...c};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    addTestFile('''
Map<String, int> c;
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    addTestFile('''
f() {
  var futureNull = Future.value(null);
  var a = {1 : 'a', ...?await futureNull, 2 : 'b'};
}
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{1'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    addTestFile('''
f() {
  var futureNull = Future.value(null);
  var a = {...?await futureNull};
}
''');
    await resolveTestFile();
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }
}
