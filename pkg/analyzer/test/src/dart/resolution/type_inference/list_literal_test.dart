// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';
import '../with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest);
    defineReflectiveTests(ListLiteralWithNnbdTest);
  });
}

@reflectiveTest
class ListLiteralTest extends DriverResolutionTest {
  test_context_noTypeArgs_expression_conflict() async {
    await resolveTestCode('''
List<int> a = ['a'];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
List<int> a = [1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_noElements() async {
    await assertNoErrorsInCode('''
List<String> a = [];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    await resolveTestCode('''
class A<E extends List<int>> {
  E a = [];
}
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    await resolveTestCode('''
class A<E extends List<dynamic>> {
  E a = [];
}
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_context_typeArgs_expression_conflictingContext() async {
    await resolveTestCode('''
List<String> a = <int>[0];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    await resolveTestCode('''
List<String> a = <String>[0];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    // Context type and element types both suggest `String`, so this should
    // override the explicit type argument.
    await assertNoErrorsInCode('''
List<String> a = <int>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
List<String> a = <String>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    await resolveTestCode('''
List<String> a = <int>[];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    await assertNoErrorsInCode('''
List<String> a = <String>[];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    await assertNoErrorsInCode('''
var a = [1, 2, 3];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    await assertNoErrorsInCode('''
var a = [1, 2.3, 4];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    await assertNoErrorsInCode('''
var a = [1, '2', 3];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_expressions_unresolved() async {
    await resolveTestCode('''
var a = [x];
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_expressions_unresolved_multiple() async {
    await resolveTestCode('''
var a = [0, x, 2];
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = [for (int e in c) e * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await assertNoErrorsInCode('''
List<int> c = [];
int b = 0;
var a = [for (b in c) b * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await assertNoErrorsInCode('''
var a = [for (var i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await assertNoErrorsInCode('''
int i = 0;
var a = [for (i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_if() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else 2.3];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else '2'];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_noElements() async {
    await assertNoErrorsInCode('''
var a = [];
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = [...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<int> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<double> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<String> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await assertNoErrorsInCode(r'''
mixin L on List<int> {}

main(L l1) {
  // ignore:unused_local_variable
  var l2 = [...l1];
}
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await resolveTestCode('''
List<int> c = [];
dynamic d;
var a = [if (0 < 1) ...c else ...d];
''');
    assertType(findNode.listLiteral('[if'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    await assertNoErrorsInCode('''
f() async {
  var futureNull = Future.value(null);
  // ignore:unused_local_variable
  var a = [1, ...?await futureNull, 2];
}
''');
    assertType(
      findNode.listLiteral('['),
      typeStringByNullability(
        nullable: 'List<int?>',
        legacy: 'List<int>',
      ),
    );
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    await assertNoErrorsInCode('''
f() async {
  var futureNull = Future.value(null);
  // ignore:unused_local_variable
  var a = [...?await futureNull];
}
''');
    assertType(findNode.listLiteral('['), 'List<Null>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    await resolveTestCode('''
var a = <String>[1];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
var a = <int>[1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    await assertNoErrorsInCode('''
var a = <int, String>[1, 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_typeArgs_noElements() async {
    await assertNoErrorsInCode('''
var a = <num>[];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }
}

@reflectiveTest
class ListLiteralWithNnbdTest extends ListLiteralTest with WithNullSafetyMixin {
  test_context_spread_nullAware() async {
    await assertNoErrorsInCode('''
T f<T>(T t) => t;

main() {
  <int>[...?f(null)];
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f(null)'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['Iterable<int>?'],
      invokeType: 'Iterable<int>? Function(Iterable<int>?)',
      type: 'Iterable<int>?',
    );
  }

  test_nested_hasNull_1() async {
    await assertNoErrorsInCode('''
main() {
  [[0], null];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int>?>');
  }

  test_nested_hasNull_2() async {
    await assertNoErrorsInCode('''
main() {
  [[0], [1, null]];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[1,'), 'List<int?>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int?>>');
  }
}
