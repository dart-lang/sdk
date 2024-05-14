// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementTest);
  });
}

@reflectiveTest
class IfStatementTest extends AbstractCompletionDriverTest
    with IfStatementTestCases {}

mixin IfStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCase() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case ^)
}

class A1 {
  A1.named();
}

const c01 = 0;

final v01 = 0;

int f01() => 0;
''');
    assertResponse(r'''
suggestions
  c01
    kind: topLevelVariable
  A1
    kind: class
  A1.named
    kind: constructor
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

  Future<void> test_afterCase_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case A^)
}

class A01 {}
class B01 {}

const A02 = 0;
const B02 = 0;

final A03 = 0;
final B03 = 0;

int A04() => 0;
int B04() => 0;
''');

    // TODO(scheglov): This is wrong.
    assertResponse(r'''
replacement
  left: 1
suggestions
  A02
    kind: topLevelVariable
  A01
    kind: class
  A01
    kind: constructorInvocation
  A03
    kind: topLevelVariable
  A04
    kind: functionInvocation
''');
  }

  Future<void> test_afterElse_beforeEnd() async {
    await computeSuggestions('''
void f() { if (true) {} else ^ }
''');
    assertResponse(r'''
suggestions
  if
    kind: keyword
  return
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterLeftParen_beforeRightParen_inFunction() async {
    await computeSuggestions('''
foo() {if (^) }
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_inFunction_partial() async {
    await computeSuggestions('''
foo() {if (n^) }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_inMethod() async {
    await computeSuggestions('''
class A {foo() {if (^) }}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  this
    kind: keyword
  const
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_inMethod_partial() async {
    await computeSuggestions('''
class A {foo() {if (n^) }}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void> test_afterPattern() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case var x ^)
}
''');
    assertResponse(r'''
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterPattern_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case var x w^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeColon_inFunction_partial() async {
    await computeSuggestions('''
foo() {if (true) r^;}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  return
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeColon_inMethod_partial() async {
    await computeSuggestions('''
class A {foo() {if (true) r^;}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  return
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeEnd_inClass() async {
    await computeSuggestions('''
class A {foo() {if (true) ^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void> test_afterRightParen_beforeEnd_inFunction() async {
    await computeSuggestions('''
foo() {if (true) ^}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void> test_afterRightParen_beforeExpressionStatement_inClass() async {
    await computeSuggestions('''
class A {foo() {if (true) ^ go();}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void>
      test_afterRightParen_beforeExpressionStatement_inFunction() async {
    await computeSuggestions('''
foo() {if (true) ^ go();}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void> test_afterRightParen_beforeSemicolon_inClass() async {
    await computeSuggestions('''
class A {foo() {if (true) ^;}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void> test_afterRightParen_beforeSemicolon_inFunction() async {
    await computeSuggestions('''
foo() {if (true) ^;}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  throw
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
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

  Future<void> test_afterThen_beforeEnd_partial() async {
    await computeSuggestions('''
void f() { if (true) {} e^ }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }

  Future<void> test_afterWhen() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case var x when ^)
}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterWhen_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case var x when c^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
''');
  }

  Future<void> test_rightParen_withCondition_withoutCase() async {
    await computeSuggestions('''
void f(Object o) {
  if (o ^) {}
}
''');
    assertResponse(r'''
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
  }

  Future<void> test_rightParen_withoutCondition() async {
    await computeSuggestions('''
void f() {
  if (^) {}
}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }
}
