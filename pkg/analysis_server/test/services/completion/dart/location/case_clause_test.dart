// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseClauseTest);
  });
}

@reflectiveTest
class CaseClauseTest extends AbstractCompletionDriverTest
    with CaseClauseTestCases {}

mixin CaseClauseTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCase_inIfElement() async {
    await computeSuggestions('''
var v = [ if (o case ^) ];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterCase_inIfStatement() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case ^) {}
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterCase_nameX_includeClass_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
class A02 {}
class B01 {}
''');
    await computeSuggestions('''
import 'a.dart';

void f(Object? x) {
  if (x case A0^) {}
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: class
  A02
    kind: constructorInvocation
''');
  }

  Future<void> test_afterCase_nameX_includeClass_local() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case A0^) {}
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: class
  A02
    kind: constructorInvocation
''');
  }

  Future<void> test_afterCase_nameX_includeClass_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
class A02 {}
class B01 {}
''');
    await computeSuggestions('''
void f(Object? x) {
  if (x case A0^) {}
}
''');
    // TODO(scheglov): this is wrong, include only const constructors.
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: class
  A02
    kind: constructorInvocation
''');
  }

  Future<void> test_afterCase_typeName_nameX() async {
    allowedIdentifiers = {'myValue', 'value'};

    await computeSuggestions('''
class MyValue {}

void f(Object? x) {
  if (x case MyValue v^) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  value
    kind: identifier
''');
  }

  Future<void> test_afterCase_typeName_x() async {
    allowedIdentifiers = {'myValue', 'value'};

    await computeSuggestions('''
class MyValue {}

void f(Object? x) {
  if (x case MyValue ^) {}
}
''');
    assertResponse(r'''
suggestions
  myValue
    kind: identifier
  value
    kind: identifier
  when
    kind: keyword
''');
  }

  Future<void> test_afterCaseClause_inIfElement() async {
    await computeSuggestions('''
var v = [ if (o case != '' ^) ];
''');
    assertResponse(r'''
suggestions
  when
    kind: keyword
''');
  }

  @FailingTest(reason: "We're proposing 'when' but shouldn't be")
  Future<void> test_afterCaseClause_inIfStatement_beforeExpression1() async {
    // The `true` isn't in the `IfStatement`, but we don't catch that case.
    await computeSuggestions('''
void f(Object o) {
  if (o case != '' ^ true) {}
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterCaseClause_inIfStatement_beforeExpression2() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case != '' ^ o.length > 3) {}
}
''');
    assertResponse(r'''
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterCaseClause_inIfStatement_beforeParen() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case != '' ^) {}
}
''');
    assertResponse(r'''
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {switch(1) {case 1:^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  case
    kind: keyword
  const
    kind: keyword
  default:
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightBrace_inFunction_partial() async {
    await computeSuggestions('''
foo() {switch(1) {case 1: b^}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  break
    kind: keyword
''');
  }

  Future<void>
      test_afterColon_beforeRightBrace_inFunction_partial_language219() async {
    await computeSuggestions('''
// @dart=2.19
foo() {switch(1) {case 1: b^}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  break
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A{foo() {switch(1) {case 1:^}}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  case
    kind: keyword
  const
    kind: keyword
  default:
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightBrace_inMethod_partial() async {
    await computeSuggestions('''
class A{foo() {switch(1) {case 1: b^}}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  break
    kind: keyword
''');
  }

  Future<void>
      test_afterColon_beforeRightBrace_inMethod_partial_language219() async {
    await computeSuggestions('''
// @dart=2.19
class A{foo() {switch(1) {case 1: b^}}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  break
    kind: keyword
''');
  }

  Future<void> test_afterWhen_inIfElement() async {
    await computeSuggestions('''
var v = [ if (o case != '' when true ^) ];
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterWhen_inIfStatement() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case != '' when true ^) {}
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_case_final_x_name() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case final ^ y) {}
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
''');
  }

  Future<void> test_case_nothing_x_name() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case ^ y) {}
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
''');
  }

  Future<void> test_declaredVariablePattern_typeX_name() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case A0^ y) {}
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A02
    kind: class
''');
  }

  Future<void> test_partialCase_inIfElement() async {
    await computeSuggestions('''
var v = [ if (o c^) ];
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
''');
  }

  Future<void> test_partialCase_inIfStatement() async {
    await computeSuggestions('''
void f(Object o) {
  if (o ca^) {}
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  case
    kind: keyword
''');
  }
}
