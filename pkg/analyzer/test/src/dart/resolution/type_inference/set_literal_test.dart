// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SetLiteralTest extends PubPackageResolutionTest {
  test_context_noTypeArgs_expression_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<int> a = {'a'};
//            ^^^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<int> a = {1};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_fromParameterType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  useSet({});
}
void useSet(Set<int> _) {}
''');
    assertType(result.findNode.setOrMapLiteral('{});'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_fromVariableType() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = {};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noElements_fromVariableType_nested() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<Set<String>> a = {{}};
''');
    assertType(result.findNode.setOrMapLiteral('{}'), 'Set<String>');
    assertType(result.findNode.setOrMapLiteral('{{}}'), 'Set<Set<String>>');
  }

  test_context_noTypeArgs_noElements_futureOr() async {
    var result = await resolveTestCode('''
import 'dart:async';

FutureOr<Set<int>> f() {
  return {};
}
''');
    assertType(result.findNode.setOrMapLiteral('{};'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends Set<int>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Set<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.setOrMapLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends Set<dynamic>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Set<dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.setOrMapLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noEntries() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = {};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T extends Object?> {
  Set<T> a = {}; // 1
  Set<T>? b = {}; // 2
  Set<T?> c = {}; // 3
  Set<T?>? d = {}; // 4
}
''');
    assertType(result.findNode.setOrMapLiteral('{}; // 1'), 'Set<T>');
    assertType(result.findNode.setOrMapLiteral('{}; // 2'), 'Set<T>');
    assertType(result.findNode.setOrMapLiteral('{}; // 3'), 'Set<T?>');
    assertType(result.findNode.setOrMapLiteral('{}; // 4'), 'Set<T?>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = <String>{0};
//                       ^
// [diag.setElementTypeNotAssignable] The element type 'int' can't be assigned to the set type 'String'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = <int>{'a'};
//              ^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Set<int>' can't be assigned to a variable of type 'Set<String>'.
//                    ^^^
// [diag.setElementTypeNotAssignable] The element type 'String' can't be assigned to the set type 'int'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = <String>{'a'};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = <int>{};
//              ^^^^^^^
// [diag.invalidAssignment] A value of type 'Set<int>' can't be assigned to a variable of type 'Set<String>'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Set<String> a = <String>{};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1, 2, 3};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1, 2.3, 4};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1, '2', 3};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = {for (int e in c) e * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
int b = 0;
var a = {for (b in c) b * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {for (var i = 0; i < 2; i++) i * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
int i = 0;
var a = {for (i = 0; i < 2; i++) i * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_if() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 else 2};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 else 2.3};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 else '2'};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = {...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<int> b = [];
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<double> b = [];
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
List<String> b = [];
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin S on Set<int> {}

void f(S s1) {
  // ignore:unused_local_variable
  var s2 = {...s1};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(result.findNode.setOrMapLiteral('{if'), 'Set<dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0};
//                   ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1, ...?a, 2};
}
''');
    assertType(result.findNode.setOrMapLiteral('{1'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Null>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsIterable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends List<int>>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0};
//                   ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
//        ^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a, 0};
//        ^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_expression_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <String>{1};
//               ^
// [diag.setElementTypeNotAssignable] The element type 'int' can't be assigned to the set type 'String'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int>{1};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int, String>{1, 2};
//                    ^
// [diag.expressionInMap] Expressions can't be used in a map literal.
//                       ^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<int>');
  }

  test_noContext_typeArgs_noElements() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <num>{};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Set<num>');
  }
}
