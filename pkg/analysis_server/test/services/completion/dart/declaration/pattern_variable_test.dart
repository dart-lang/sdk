// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableTest1);
    defineReflectiveTests(PatternVariableTest2);
  });
}

@reflectiveTest
class PatternVariableTest1 extends AbstractCompletionDriverTest
    with PatternVariableTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class PatternVariableTest2 extends AbstractCompletionDriverTest
    with PatternVariableTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin PatternVariableTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_castPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 as int: ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_ifElement_else() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12)) 0 else ^];
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_ifElement_else_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12)) 0 else a^];
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_ifElement_then() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12)) ^];
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifElement_then_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12)) a^];
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifElement_when() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12) when ^) 0];
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifElement_when_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  [if (a01 case (var a11, var a12) when a^) 0];
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifStatement_else() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12)) {} else {^}
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_ifStatement_else_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12)) {} else {a^}
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_ifStatement_then() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12)) {^}
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifStatement_then_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12)) {a^}
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifStatement_when() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12) when ^) {}
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_ifStatement_when_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  if (a01 case (var a11, var a12) when a^) {}
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_listPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case [var a11, var a12, ... var a13]: ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchExpression_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
    var a11 && var a11 => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchExpression_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 && var a11 => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchExpression_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 && var a12 => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchExpression_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 && var a12 => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchStatement_multiple_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a11:
    case var a11 && var a11:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchStatement_multiple_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a11:
    case var a11 && var a11:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchStatement_multiple_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a12:
    case var a13 && var a14:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
  a14
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchStatement_multiple_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a12:
    case var a13 && var a14:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
  a14
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchStatement_single_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a11:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchStatement_single_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a11:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalAnd_switchStatement_single_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a12:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void>
      test_logicalAnd_switchStatement_single_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 && var a12:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchExpression_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 || var a11 => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchExpression_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 || var a11 => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchExpression_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 || var a12 => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchExpression_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  var x = switch (a01) {
   var a11 || var a12 => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchStatement_multiple_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a11:
    case var a11 || var a11:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void>
      test_logicalOr_switchStatement_multiple_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a11:
    case var a11 || var a11:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchStatement_multiple_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a12:
    case var a13 || var a14:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
  a14
    kind: localVariable
''');
  }

  Future<void>
      test_logicalOr_switchStatement_multiple_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a12:
    case var a13 || var a14:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
  a14
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchStatement_single_intersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a11:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void>
      test_logicalOr_switchStatement_single_intersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a11:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_logicalOr_switchStatement_single_nonIntersecting() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a12:
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void>
      test_logicalOr_switchStatement_single_nonIntersecting_partial() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11 || var a12:
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_mapPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case {1: var a11, 2: var a12, ... var a13}: ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
  a13
    kind: localVariable
''');
  }

  Future<void> test_nullAssertPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11!: ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_nullCheckPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case var a11?: ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_objectPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case C(a: var a11, b: var a12): ^
}
class C {
  int get a => 0;
  int get b => 0;
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_parenthesizedPattern() async {
    await computeSuggestions('''
void f(Object a01) {
  switch (a01) {
    case (var a11): ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
''');
  }

  Future<void> test_patternDeclarationStatement_closure() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = a01;
  () {^}
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_patternDeclarationStatement_closure_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = a01;
  () {a^}
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_patternDeclarationStatement_initializer() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = ^;
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_patternDeclarationStatement_initializer_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = a^;
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_patternDeclarationStatement_nextStatement() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = a01;
  ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_patternDeclarationStatement_nextStatement_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var (a11, a12) = a01;
  a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_patternDeclarationStatement_previousStatement() async {
    await computeSuggestions('''
void f((int, int) a01) {
  ^
  var (a11, a12) = a01;
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void>
      test_patternDeclarationStatement_previousStatement_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  a^
  var (a11, a12) = a01;
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchExpressionCase_different() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var x = switch (a01) {
    (0, var a12) => '',
    (1, 0) => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchExpressionCase_different_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var x = switch (a01) {
    (0, var a12) => '',
    (1, 0) => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchExpressionCase_same() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var x = switch (a01) {
   (var a11, var a12) => ^
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_switchExpressionCase_same_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  var x = switch (a01) {
    (var a11, var a12) => a^
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_switchStatementCase_different_first_explicit() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (1, 0):
      ^
      break;
    case (0, var a12):
      break;
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void>
      test_switchStatementCase_different_first_explicit_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (1, 0):
      a^
      break;
    case (0, var a12):
      break;
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchStatementCase_different_first_implicit() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (1, 0):
      ^
    case (0, var a12):
      break;
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void>
      test_switchStatementCase_different_first_implicit_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (1, 0):
      a^
    case (0, var a12):
      break;
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchStatementCase_different_last() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (0, var a12):
      break;
    case (1, 0):
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchStatementCase_different_last_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (0, var a12):
      break;
    case (1, 0):
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
''');
  }

  Future<void> test_switchStatementCase_same_multiple_intersecting() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (var a11, var a12):
    case (var a11, var a12):
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void>
      test_switchStatementCase_same_multiple_intersecting_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (var a11, var a12):
    case (var a11, var a12):
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_switchStatementCase_same_multiple_nonIntersecting() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (0, 0):
    case (var a11, var a12):
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void>
      test_switchStatementCase_same_multiple_nonIntersecting_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (0, 0):
    case (var a11, var a12):
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_switchStatementCase_same_single() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (var a11, var a12):
      ^
  }
}
''');

    assertResponse(r'''
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }

  Future<void> test_switchStatementCase_same_single_partial() async {
    await computeSuggestions('''
void f((int, int) a01) {
  switch (a01) {
    case (var a11, var a12):
      a^
  }
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  a01
    kind: parameter
  a11
    kind: localVariable
  a12
    kind: localVariable
''');
  }
}
