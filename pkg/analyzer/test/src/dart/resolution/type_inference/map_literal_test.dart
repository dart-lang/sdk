// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapLiteralTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MapLiteralTest extends PubPackageResolutionTest {
  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_entry_conflictingKey() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {'a' : 1};
//                 ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_conflictingValue() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {1 : 'a'};
//                     ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_noElements_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<Map<int, String>> f() {
  return {};
}
''');
    assertType(setOrMapLiteral('{};'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromParameterType() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  useMap({});
}
void useMap(Map<int, String> _) {}
''');
    assertType(setOrMapLiteral('{})'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromVariableType() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    await resolveTestCodeWithDiagnostics('''
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

  test_context_noTypeArgs_noEntries_typeParameters() async {
    await resolveTestCodeWithDiagnostics('''
class A<E extends Map<int, String>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_noTypeArgs_noEntries_typeParameters_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
class A<E extends Map<dynamic, dynamic>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_spread_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
T f<T>(T t) => t;

main() {
  <int, double>{...?f(null)};
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
          substitution: {T: Map<int, double>?}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: Map<int, double>? Function(Map<int, double>?)
  staticType: Map<int, double>?
  typeArgumentTypes
    Map<int, double>?
''');
  }

  test_context_typeArgs_entry_conflictingKey() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{0 : 'a'};
//                                       ^
// [diag.mapKeyTypeNotAssignable] The element type 'int' can't be assigned to the map key type 'String'.
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflictingValue() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{'a' : 1};
//                                             ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <int, int>{};
//                      ^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, int>' can't be assigned to a variable of type 'Map<String, String>'.
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_default_constructor_param_typed() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  const C({x = const <String, int>{}});
}
''');
  }

  test_default_constructor_param_untyped() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  const C({x = const {}});
}
''');
  }

  test_noContext_noTypeArgs_expressions_lubOfIntAndString() async {
    await resolveTestCodeWithDiagnostics('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNumAndNum() async {
    await resolveTestCodeWithDiagnostics('''
var a = {1 : 2, 3.0 : 4, 5 : 6.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObjectAndObject() async {
    await resolveTestCodeWithDiagnostics('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = {for (int e in c) e : e * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
List<int> c = [];
int b = 0;
var a = {for (b in c) b * 2 : b};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await resolveTestCodeWithDiagnostics('''
int i = 0;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfIntAndInt() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNumAndNum() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1.0 : 3 else 2 : 4.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObjectAndObject() async {
    await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    await resolveTestCodeWithDiagnostics('''
var a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
var c = {};
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_lubOfIntAndInt() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
Map<int, int> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNumAndNum() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, double> c = {};
Map<double, int> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObjectObject() async {
    await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
Map<String, String> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Map<String, int> {}

void f(M m1) {
  // ignore:unused_local_variable
  var m2 = {...m1};
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<String, int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await resolveTestCodeWithDiagnostics('''
Map<String, int> c = {};
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(setOrMapLiteral('{if'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
//                   ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//                                ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_map() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1 : 'a', ...?a, 2 : 'b'};
}
''');
    assertType(setOrMapLiteral('{1'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_set() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1, ...?a, 2};
}
''');
    assertType(setOrMapLiteral('{1'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {...?a};
//        ^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_never() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_null() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Null>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//                                ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsMap() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Map<int, String>>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_never() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
//                   ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  // TODO(scheglov): Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
//        ^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  // TODO(scheglov): Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap2() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a, 0: 1};
//        ^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_entry_conflictingKey() async {
    await resolveTestCodeWithDiagnostics('''
var a = <String, int>{1 : 2};
//                    ^
// [diag.mapKeyTypeNotAssignable] The element type 'int' can't be assigned to the map key type 'String'.
''');
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_conflictingValue() async {
    await resolveTestCodeWithDiagnostics('''
var a = <String, int>{'a' : 'b'};
//                          ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
var a = <int, int>{1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_expression_conflictingElement() async {
    await resolveTestCodeWithDiagnostics('''
var a = <int, String>{1};
//                    ^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  @SkippedTest() // TODO(scheglov): fix it
  test_noContext_typeArgs_expressions_conflictingTypeArgs() async {
    await resolveTestCodeWithDiagnostics('''
var a = <int>{1 : 2, 3 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    await resolveTestCodeWithDiagnostics('''
var a = <num, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, String>');
  }
}
