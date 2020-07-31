// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralTest);
    defineReflectiveTests(SetLiteralWithNnbdTest);
  });
}

@reflectiveTest
class SetLiteralTest extends DriverResolutionTest {
  AstNode setLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_expression_conflict() async {
    await resolveTestCode('''
Set<int> a = {'a'};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    await resolveTestCode('''
Set<int> a = {1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements() async {
    await resolveTestCode('''
Set<String> a = {};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    await resolveTestCode('''
class A<E extends Set<int>> {
  E a = {};
}
''');
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    await resolveTestCode('''
class A<E extends Set<dynamic>> {
  E a = {};
}
''');
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    await resolveTestCode('''
Set<String> a = <String>{0};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    await resolveTestCode('''
Set<String> a = <int>{'a'};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    await resolveTestCode('''
Set<String> a = <String>{'a'};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    await resolveTestCode('''
Set<String> a = <int>{};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    await resolveTestCode('''
Set<String> a = <String>{};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    await resolveTestCode('''
var a = {1, 2, 3};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    await resolveTestCode('''
var a = {1, 2.3, 4};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    await resolveTestCode('''
var a = {1, '2', 3};
''');
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await resolveTestCode('''
List<int> c;
var a = {for (int e in c) e * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await resolveTestCode('''
List<int> c;
int b;
var a = {for (b in c) b * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await resolveTestCode('''
var a = {for (var i = 0; i < 2; i++) i * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await resolveTestCode('''
int i;
var a = {for (i = 0; i < 2; i++) i * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_if() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 else 2};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 else 2.3};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 else '2'};
''');
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread() async {
    await resolveTestCode('''
List<int> c;
var a = {...c};
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    await resolveTestCode('''
List<int> c;
List<int> b;
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    await resolveTestCode('''
List<int> c;
List<double> b;
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    await resolveTestCode('''
List<int> c;
List<String> b;
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await resolveTestCode(r'''
mixin S on Set<int> {}
main() {
  S s1;
  var s2 = {...s1};
}
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await resolveTestCode('''
List<int> c;
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(setLiteral('{'), 'Set<dynamic>');
  }

  @failingTest
  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    await resolveTestCode('''
f() {
  var futureNull = Future.value(null);
  var a = {1, ...?await futureNull, 2};
}
''');
    assertType(setLiteral('{1'), 'Set<int>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    await resolveTestCode('''
var a = <String>{1};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    await resolveTestCode('''
var a = <int>{1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    await resolveTestCode('''
var a = <int, String>{1, 2};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_typeArgs_noElements() async {
    await resolveTestCode('''
var a = <num>{};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }
}

@reflectiveTest
class SetLiteralWithNnbdTest extends SetLiteralTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  @override
  bool get typeToStringWithNullability => true;

  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_noEntries() async {
    await resolveTestCode('''
Set<String> a = {};
''');
    assertType(setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    await resolveTestCode('''
class C<T extends Object?> {
  Set<T> a = {}; // 1
  Set<T>? b = {}; // 2
  Set<T?> c = {}; // 3
  Set<T?>? d = {}; // 4
}
''');
    assertType(setOrMapLiteral('{}; // 1'), 'Set<T>');
    assertType(setOrMapLiteral('{}; // 2'), 'Set<T>');
    assertType(setOrMapLiteral('{}; // 3'), 'Set<T?>');
    assertType(setOrMapLiteral('{}; // 4'), 'Set<T?>');
  }
}
