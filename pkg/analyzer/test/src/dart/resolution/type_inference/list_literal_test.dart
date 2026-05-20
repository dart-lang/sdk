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
    await resolveTestCodeWithDiagnostics('''
List<int> a = ['a'];
//             ^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
''');
    assertType(findNode.listLiteral('[\'a\']'), 'List<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
List<int> a = [1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromReturnType() async {
    await resolveTestCodeWithDiagnostics('''
List<int> f() {
  return [];
}
''');
    assertType(findNode.listLiteral('[]'), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromVariableType() async {
    await resolveTestCodeWithDiagnostics('''
List<String> a = [];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A<E extends List<int>> {
  E a = [];
//      ^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(findNode.listLiteral('[]'), 'List<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
class A<E extends List<dynamic>> {
  E a = [];
//      ^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(findNode.listLiteral('[]'), 'List<dynamic>');
  }

  test_context_spread_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
T f<T>(T t) => t;

main() {
  <int>[...?f(null)];
}
''');

    var node = findNode.methodInvocation('f(null)');
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
        correspondingParameter: ParameterMember
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
    await resolveTestCodeWithDiagnostics('''
List<String> a = <int>[0];
//               ^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<int>' can't be assigned to a variable of type 'List<String>'.
''');
    assertType(findNode.listLiteral('<int>['), 'List<int>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    await resolveTestCodeWithDiagnostics('''
List<String> a = <String>[0];
//                        ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
    assertType(findNode.listLiteral('<String>['), 'List<String>');
  }

  @SkippedTest() // TODO(scheglov): fix it
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    // Context type and element types both suggest `String`, so this should
    // override the explicit type argument.
    await resolveTestCodeWithDiagnostics('''
List<String> a = <int>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
List<String> a = <String>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    await resolveTestCodeWithDiagnostics('''
List<String> a = <int>[];
//               ^^^^^^^
// [diag.invalidAssignment] A value of type 'List<int>' can't be assigned to a variable of type 'List<String>'.
''');
    assertType(findNode.listLiteral('<int>['), 'List<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
List<String> a = <String>[];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_nested_hasNull_1() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  [[0], null];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int>?>');
  }

  test_nested_hasNull_2() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  [[0], [1, null]];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[1,'), 'List<int?>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int?>>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    await resolveTestCodeWithDiagnostics('''
var a = [1, 2, 3];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    await resolveTestCodeWithDiagnostics('''
var a = [1, 2.3, 4];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    await resolveTestCodeWithDiagnostics('''
var a = [1, '2', 3];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_expressions_unresolved() async {
    await resolveTestCodeWithDiagnostics('''
var a = [x];
//       ^
// [diag.undefinedIdentifier] Undefined name 'x'.
''');
    assertType(findNode.listLiteral('[x]'), 'List<InvalidType>');
  }

  test_noContext_noTypeArgs_expressions_unresolved_multiple() async {
    await resolveTestCodeWithDiagnostics('''
var a = [0, x, 2];
//          ^
// [diag.undefinedIdentifier] Undefined name 'x'.
''');
    assertType(findNode.listLiteral('[0, x'), 'List<InvalidType>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = [for (int e in c) e * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
int b = 0;
var a = [for (b in c) b * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
var a = [for (var i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await resolveTestCodeWithDiagnostics('''
int i = 0;
var a = [for (i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_if() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else 2.3];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = [if (c) 1 else '2'];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_noElements() async {
    await resolveTestCodeWithDiagnostics('''
var a = [];
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = [...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<int> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<double> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<String> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin L on List<int> {}

void f(L l1) {
  // ignore:unused_local_variable
  var l2 = [...l1];
}
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
dynamic d;
var a = [if (0 < 1) ...c else ...d];
''');
    assertType(findNode.listLiteral('[if'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    await resolveTestCodeWithDiagnostics('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('[...a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    await resolveTestCodeWithDiagnostics('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...?a];
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
}
''');
    assertType(findNode.listLiteral('[...?a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [...?a];
}
''');
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null2() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [1, ...?a, 2];
}
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNever() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
}
''');
    assertType(findNode.listLiteral('[...?a]'), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNull() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Null>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
}
''');
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsIterable() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends List<int>>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsNever() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
//            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
    assertType(findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable2() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a, 0];
//            ^
// [diag.notIterableSpread] Spread elements in list or set literals must implement 'Iterable'.
}
''');
    assertType(findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    await resolveTestCodeWithDiagnostics('''
var a = <String>[1];
//               ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
''');
    assertType(findNode.listLiteral('<String>['), 'List<String>');
  }

  test_noContext_typeArgs_expression_conflict_nullable() async {
    await resolveTestCodeWithDiagnostics('''
var a = <String>[(null as String?)];
//               ^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignableNullability] The element type 'String?' can't be assigned to the list type 'String'.
''');
    assertType(findNode.listLiteral('<String>['), 'List<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
var a = <int>[1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  @SkippedTest() // TODO(scheglov): fix it
  test_noContext_typeArgs_expressions_conflict() async {
    await resolveTestCodeWithDiagnostics('''
var a = <int, String>[1, 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_typeArgs_noElements() async {
    await resolveTestCodeWithDiagnostics('''
var a = <num>[];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }
}
