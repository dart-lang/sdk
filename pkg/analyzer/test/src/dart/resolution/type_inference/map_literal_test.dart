// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_context_noTypeArgs_entry_conflictingKey() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {'a' : 1};
//                 ^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_conflictingValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {1 : 'a'};
//                     ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> a = {1 : 2};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_expression() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw 0;

Map<String, int> a = {f()};
//                    ^^^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MethodInvocation
      methodName: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: String Function()
      staticType: String
      typeArgumentTypes
        String
  rightBracket: }
  isMap: true
  staticType: Map<String, int>
''');
  }

  test_context_noTypeArgs_expression_dotShorthand() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { one }

Map<E, String> a = {.one};
//                  ^^^^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: one
        element: <testLibrary>::@enum::E::@getter::one
        staticType: E
      isDotShorthand: true
      staticType: E
  rightBracket: }
  isMap: true
  staticType: Map<E, String>
''');
  }

  test_context_noTypeArgs_expression_dotShorthand_missingIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { one }

Map<E, String> a = {.};
//                  ^
// [diag.expressionInMap] Expressions can't be used in a map literal.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.dotShorthandUndefinedGetter][column 22][length 0] The static getter '' isn't defined for the context type 'E'.
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: <empty> <synthetic>
        element: <null>
        staticType: InvalidType
      isDotShorthand: true
      staticType: InvalidType
  rightBracket: }
  isMap: true
  staticType: Map<E, String>
''');
  }

  test_context_noTypeArgs_if_expression() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw 0;

Map<String, int> a = {if (true) f()};
//                              ^^^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
        staticType: bool
      rightParenthesis: )
      thenElement: MethodInvocation
        methodName: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
  rightBracket: }
  isMap: true
  staticType: Map<String, int>
''');
  }

  test_context_noTypeArgs_noElements_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<Map<int, String>> f() {
  return {};
}
''');
    assertType(result.findNode.setOrMapLiteral('{};'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromParameterType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  useMap({});
}
void useMap(Map<int, String> _) {}
''');
    assertType(result.findNode.setOrMapLiteral('{})'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromVariableType() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = {};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T extends Object?> {
  Map<String, T> a = {}; // 1
  Map<String, T>? b = {}; // 2
  Map<String, T?> c = {}; // 3
  Map<String, T?>? d = {}; // 4
}
''');
    assertType(result.findNode.setOrMapLiteral('{}; // 1'), 'Map<String, T>');
    assertType(result.findNode.setOrMapLiteral('{}; // 2'), 'Map<String, T>');
    assertType(result.findNode.setOrMapLiteral('{}; // 3'), 'Map<String, T?>');
    assertType(result.findNode.setOrMapLiteral('{}; // 4'), 'Map<String, T?>');
  }

  test_context_noTypeArgs_noEntries_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends Map<int, String>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_noTypeArgs_noEntries_typeParameters_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E extends Map<dynamic, dynamic>> {
  E a = {};
//      ^^
// [diag.invalidAssignment] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'E'.
}
''');
    assertType(result.findNode.setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_spread_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>(T t) => t;

main() {
  <int, double>{...?f(null)};
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
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{0 : 'a'};
//                                       ^
// [diag.mapKeyTypeNotAssignable] The element type 'int' can't be assigned to the map key type 'String'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflictingValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{'a' : 1};
//                                             ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <int, int>{};
//                      ^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<int, int>' can't be assigned to a variable of type 'Map<String, String>'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, String> a = <String, String>{};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, String>');
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
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNumAndNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1 : 2, 3.0 : 4, 5 : 6.0};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObjectAndObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
var a = {for (int e in c) e : e * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<int> c = [];
int b = 0;
var a = {for (b in c) b * 2 : b};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
int i = 0;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    assertType(result.findNode.setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : 2};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfIntAndInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNumAndNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1.0 : 3 else 2 : 4.0};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObjectAndObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
bool c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = {};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
var a = {...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
var c = {};
var a = {...c};
''');
    assertType(
      result.findNode.setOrMapLiteral('{...'),
      'Map<dynamic, dynamic>',
    );
  }

  test_noContext_noTypeArgs_spread_lubOfIntAndInt() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
Map<int, int> b = {};
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNumAndNum() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, double> c = {};
Map<double, int> b = {};
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObjectObject() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<int, int> c = {};
Map<String, String> b = {};
var a = {...b, ...c};
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M on Map<String, int> {}

void f(M m1) {
  // ignore:unused_local_variable
  var m2 = {...m1};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<String, int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    var result = await resolveTestCodeWithDiagnostics('''
Map<String, int> c = {};
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(result.findNode.setOrMapLiteral('{if'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
//                   ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//                                ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_map() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1 : 'a', ...?a, 2 : 'b'};
}
''');
    assertType(result.findNode.setOrMapLiteral('{1'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_set() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1, ...?a, 2};
}
''');
    assertType(result.findNode.setOrMapLiteral('{1'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {...?a};
//        ^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//         ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
//                    ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Null>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
//                                ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsMap() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Map<int, String>>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
//                   ^^^^^^^^^^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  // TODO(scheglov): Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap() async {
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

  // TODO(scheglov): Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a, 0: 1};
//        ^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
}
''');
    assertType(result.findNode.setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_entry_conflictingKey() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <String, int>{1 : 2};
//                    ^
// [diag.mapKeyTypeNotAssignable] The element type 'int' can't be assigned to the map key type 'String'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_conflictingValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <String, int>{'a' : 'b'};
//                          ^^^
// [diag.mapValueTypeNotAssignable] The element type 'String' can't be assigned to the map value type 'int'.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int, int>{1 : 2};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_expression_conflictingElement() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int, String>{1};
//                    ^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, String>');
  }

  @FailingTest() // TODO(scheglov): fix it
  test_noContext_typeArgs_expressions_conflictingTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <int>{1 : 2, 3 : 4};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    var result = await resolveTestCodeWithDiagnostics('''
var a = <num, String>{};
''');
    assertType(result.findNode.setOrMapLiteral('{'), 'Map<num, String>');
  }
}
