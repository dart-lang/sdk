// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ListLiteralTest extends PubPackageResolutionTest {
  test_context_noTypeArgs_expression_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> a = ['a'];
//             ^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
    assertType(result.findNode.listLiteral('[\'a\']'), 'List<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> a = [1];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromReturnType() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> f() {
  return [];
}
''');
    assertType(result.findNode.listLiteral('[]'), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromVariableType() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = [];
''');
    assertType(result.findNode.listLiteral('['), 'List<String>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends List<int>> {
  E a = [];
//      ^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.listLiteral('[]'), 'List<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends List<dynamic>> {
  E a = [];
//      ^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.listLiteral('[]'), 'List<dynamic>');
  }

  test_context_spread_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>(T t) => t;

main() {
  <int>[...?f(null)];
}
''');

    var node = result.findNode.methodInvocation('f(null)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::f::@formalParameter::t
          substitution: {T: Iterable<int>?}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: Iterable<int>? Function(Iterable<int>?)
  staticType: Iterable<int>?
  typeArgumentTypes
    Iterable<int>?
''');
  }

  test_context_typeArgs_expression_conflictingContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <int>[0];
//               ^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<int>' can't be assigned to a variable of type 'List<String>'.
''');
    assertType(result.findNode.listLiteral('<int>['), 'List<int>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <String>[0];
//                        ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
    assertType(result.findNode.listLiteral('<String>['), 'List<String>');
  }

  @FailingTest() // TODO(scheglov): fix it
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    // Context type and element types both suggest `String`, so this should
    // override the explicit type argument.
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <int>['a'];
''');
    assertType(result.findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <String>['a'];
''');
    assertType(result.findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <int>[];
//               ^^^^^^^
// [diag.invalidAssignment] A value of type 'List<int>' can't be assigned to a variable of type 'List<String>'.
''');
    assertType(result.findNode.listLiteral('<int>['), 'List<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<String> a = <String>[];
''');
    assertType(result.findNode.listLiteral('['), 'List<String>');
  }

  test_nested_hasNull_1() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  [[0], null];
}
''');
    assertType(result.findNode.listLiteral('[0'), 'List<int>');
    assertType(result.findNode.listLiteral('[[0'), 'List<List<int>?>');
  }

  test_nested_hasNull_2() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  [[0], [1, null]];
}
''');
    assertType(result.findNode.listLiteral('[0'), 'List<int>');
    assertType(result.findNode.listLiteral('[1,'), 'List<int?>');
    assertType(result.findNode.listLiteral('[[0'), 'List<List<int?>>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [1, 2, 3];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [1, 2.3, 4];
''');
    assertType(result.findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [1, '2', 3];
''');
    assertType(result.findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_expressions_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [x];
//       ^
// [diag.undefinedIdentifier] Undefined name 'x'.
''');
    assertType(result.findNode.listLiteral('[x]'), 'List<InvalidType>');
  }

  test_noContext_noTypeArgs_expressions_unresolved_multiple() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [0, x, 2];
//          ^
// [diag.undefinedIdentifier] Undefined name 'x'.
''');
    assertType(result.findNode.listLiteral('[0, x'), 'List<InvalidType>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = [for (int e in c) e * 2];
''');
    assertType(result.findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
int b = 0;
var a = [for (b in c) b * 2];
''');
    assertType(result.findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [for (var i = 0; i < 2; i++) i * 2];
''');
    assertType(result.findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
int i = 0;
var a = [for (i = 0; i < 2; i++) i * 2];
''');
    assertType(result.findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_if() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else 2];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else 2.3];
''');
    assertType(result.findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else '2'];
''');
    assertType(result.findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_noElements() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = [];
''');
    assertType(result.findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = [...c];
''');
    assertType(result.findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<int> b = [];
var a = [...b, ...c];
''');
    assertType(result.findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<double> b = [];
var a = [...b, ...c];
''');
    assertType(result.findNode.listLiteral('[...'), 'List<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<String> b = [];
var a = [...b, ...c];
''');
    assertType(result.findNode.listLiteral('[...'), 'List<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin L on List<int> {}

void f(L l1) {
  // ignore:unused_local_variable
  var l2 = [...l1];
}
''');
    assertType(result.findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
dynamic d;
var a = [if (0 < 1) ...c else ...d];
''');
    assertType(result.findNode.listLiteral('[if'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(result.findNode.listLiteral('[...a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...?a];
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
}
''');
    assertType(result.findNode.listLiteral('[...?a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [...?a];
}
''');
    assertType(result.findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [1, ...?a, 2];
}
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNever() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
}
''');
    assertType(result.findNode.listLiteral('[...?a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Null>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
}
''');
    assertType(result.findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsIterable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends List<int>>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(result.findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsNever() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(result.findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
//            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
    assertType(result.findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a, 0];
//            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
    assertType(result.findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <String>[1];
//               ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
    assertType(result.findNode.listLiteral('<String>['), 'List<String>');
  }

  test_noContext_typeArgs_expression_conflict_nullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <String>[(null as String?)];
//               ^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignableNullability] The element type 'String?' can't be assigned to the list type 'String'.
''');
    assertType(result.findNode.listLiteral('<String>['), 'List<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int>[1];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  @FailingTest() // TODO(scheglov): fix it
  test_noContext_typeArgs_expressions_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int, String>[1, 2];
''');
    assertType(result.findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_typeArgs_noElements() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <num>[];
''');
    assertType(result.findNode.listLiteral('['), 'List<num>');
  }
}
