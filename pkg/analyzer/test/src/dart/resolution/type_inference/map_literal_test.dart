// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapLiteralTest);
    defineReflectiveTests(MapLiteralWithNnbdTest);
  });
}

@reflectiveTest
class MapLiteralTest extends DriverResolutionTest {
  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_entry_conflictingKey() async {
    await resolveTestCode('''
Map<int, int> a = {'a' : 1};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_conflictingValue() async {
    await resolveTestCode('''
Map<int, int> a = {1 : 'a'};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    await resolveTestCode('''
Map<int, int> a = {1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_noEntries() async {
    await resolveTestCode('''
Map<String, String> a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_noTypeArgs_noEntries_typeParameters() async {
    await resolveTestCode('''
class A<E extends Map<int, String>> {
  E a = {};
}
''');
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_noTypeArgs_noEntries_typeParameters_dynamic() async {
    await resolveTestCode('''
class A<E extends Map<dynamic, dynamic>> {
  E a = {};
}
''');
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_typeArgs_entry_conflictingKey() async {
    await resolveTestCode('''
Map<String, String> a = <String, String>{0 : 'a'};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflictingValue() async {
    await resolveTestCode('''
Map<String, String> a = <String, String>{'a' : 1};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    await resolveTestCode('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    await resolveTestCode('''
Map<String, String> a = <int, int>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    await resolveTestCode('''
Map<String, String> a = <String, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_default_constructor_param_typed() async {
    await resolveTestCode('''
class C {
  const C({x = const <String, int>{}});
}
''');
  }

  test_default_constructor_param_untyped() async {
    await resolveTestCode('''
class C {
  const C({x = const {}});
}
''');
  }

  test_noContext_noTypeArgs_expressions_lubOfIntAndString() async {
    await resolveTestCode('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNumAndNum() async {
    await resolveTestCode('''
var a = {1 : 2, 3.0 : 4, 5 : 6.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObjectAndObject() async {
    await resolveTestCode('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await resolveTestCode('''
List<int> c;
var a = {for (int e in c) e : e * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await resolveTestCode('''
List<int> c;
int b;
var a = {for (b in c) b * 2 : b};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await resolveTestCode('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await resolveTestCode('''
int i;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfIntAndInt() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNumAndNum() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1.0 : 3 else 2 : 4.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObjectAndObject() async {
    await resolveTestCode('''
bool c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    await resolveTestCode('''
var a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await resolveTestCode('''
Map<int, int> c;
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_dynamic() async {
    await resolveTestCode('''
var c = {};
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_lubOfIntAndInt() async {
    await resolveTestCode('''
Map<int, int> c;
Map<int, int> b;
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNumAndNum() async {
    await resolveTestCode('''
Map<int, double> c;
Map<double, int> b;
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObjectObject() async {
    await resolveTestCode('''
Map<int, int> c;
Map<String, String> b;
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await resolveTestCode(r'''
mixin M on Map<String, int> {}
main() {
  M m1;
  var m2 = {...m1};
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<String, int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await resolveTestCode('''
Map<String, int> c;
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_map() async {
    await assertNoErrorsInCode('''
f() async {
  var futureNull = Future.value(null);
  var a = {1 : 'a', ...?await futureNull, 2 : 'b'};
  a;
}
''');
    assertType(
      setOrMapLiteral('{1'),
      typeStringByNullability(
        nullable: 'Map<int?, String?>',
        legacy: 'Map<int, String>',
      ),
    );
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_set() async {
    await assertNoErrorsInCode('''
f() async {
  var futureNull = Future.value(null);
  var a = {1, ...?await futureNull, 2};
  a;
}
''');
    assertType(
      setOrMapLiteral('{1'),
      typeStringByNullability(
        nullable: 'Set<int?>',
        legacy: 'Set<int>',
      ),
    );
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    await assertErrorsInCode('''
f() async {
  var futureNull = Future.value(null);
  var a = {...?await futureNull};
  a;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 61, 22),
    ]);
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_entry_conflictingKey() async {
    await resolveTestCode('''
var a = <String, int>{1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_conflictingValue() async {
    await resolveTestCode('''
var a = <String, int>{'a' : 'b'};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    await resolveTestCode('''
var a = <int, int>{1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_expression_conflictingElement() async {
    await resolveTestCode('''
var a = <int, String>{1};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflictingTypeArgs() async {
    await resolveTestCode('''
var a = <int>{1 : 2, 3 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    await resolveTestCode('''
var a = <num, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, String>');
  }
}

@reflectiveTest
class MapLiteralWithNnbdTest extends MapLiteralTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  @override
  bool get typeToStringWithNullability => true;

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    await resolveTestCode('''
class C<T extends Object?> {
  Map<String, T> a = {}; // 1
  Map<String, T>? b = {}; // 2
  Map<String, T?> c = {}; // 3
  Map<String, T?>? d = {}; // 4
}
''');
    assertType(setOrMapLiteral('{}; // 1'), 'Map<String, T>');
    assertType(setOrMapLiteral('{}; // 2'), 'Map<String, T>');
    assertType(setOrMapLiteral('{}; // 3'), 'Map<String, T?>');
    assertType(setOrMapLiteral('{}; // 4'), 'Map<String, T?>');
  }

  test_context_spread_nullAware() async {
    await assertNoErrorsInCode('''
T f<T>(T t) => t;

main() {
  <int, double>{...?f(null)};
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f(null)'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['Map<int, double>?'],
      invokeType: 'Map<int, double>? Function(Map<int, double>?)',
      type: 'Map<int, double>?',
    );
  }
}
