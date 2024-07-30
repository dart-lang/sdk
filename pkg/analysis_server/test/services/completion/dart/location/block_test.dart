// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlockInCatchClauseTest);
    defineReflectiveTests(BlockInDoStatementTest);
    defineReflectiveTests(BlockInForStatementTest);
    defineReflectiveTests(BlockInFunctionBodyTest);
    defineReflectiveTests(BlockInFunctionExpressionBodyTest);
    defineReflectiveTests(BlockInLocalFunctionBodyTest);
    defineReflectiveTests(BlockInMethodBodyTest);
    defineReflectiveTests(BlockInWhileStatementTest);
    defineReflectiveTests(BlockTest);
  });
}

@reflectiveTest
class BlockInCatchClauseTest extends AbstractCompletionDriverTest
    with CatchClauseTestCases {}

@reflectiveTest
class BlockInDoStatementTest extends AbstractCompletionDriverTest
    with DoStatementTestCases {}

@reflectiveTest
class BlockInForStatementTest extends AbstractCompletionDriverTest
    with ForStatementTestCases {}

@reflectiveTest
class BlockInFunctionBodyTest extends AbstractCompletionDriverTest
    with FunctionBodyTestCases {}

@reflectiveTest
class BlockInFunctionExpressionBodyTest extends AbstractCompletionDriverTest
    with FunctionExpressionBodyTestCases {}

@reflectiveTest
class BlockInLocalFunctionBodyTest extends AbstractCompletionDriverTest
    with LocalFunctionBodyTestCases {}

@reflectiveTest
class BlockInMethodBodyTest extends AbstractCompletionDriverTest
    with MethodBodyTestCases {}

@reflectiveTest
class BlockInWhileStatementTest extends AbstractCompletionDriverTest
    with WhileStatementTestCases {}

@reflectiveTest
class BlockTest extends AbstractCompletionDriverTest with BlockTestCases {}

mixin BlockTestCases on AbstractCompletionDriverTest {
  static final spaces_4 = ' ' * 4;
  static final spaces_6 = ' ' * 6;
  static final spaces_8 = ' ' * 8;

  Future<void> test_flutter_setState_indent6_hasPrefix() async {
    await _check_flutter_setState(line: '${spaces_6}setSt^', expected: '''
replacement
  left: 5
suggestions
  setState(() {
$spaces_8
$spaces_6});
    kind: invocation
    selection: 22
''');
  }

  Future<void> test_flutter_setState_indent_hasPrefix() async {
    await _check_flutter_setState(line: '${spaces_4}setSt^', expected: '''
replacement
  left: 5
suggestions
  setState(() {
$spaces_6
$spaces_4});
    kind: invocation
    selection: 20
''');
  }

  Future<void> test_flutter_setState_indent_noPrefix() async {
    await _check_flutter_setState(line: '$spaces_4^', expected: '''
suggestions
  setState(() {
$spaces_6
$spaces_4});
    kind: invocation
    selection: 20
''');
  }

  Future<void> _check_flutter_setState({
    required String line,
    required String expected,
  }) async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatefulWidget {
  @override
  State<TestWidget> createState() {
    return TestWidgetState();
  }
}

class TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
$line
  }
}
''');

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return suggestion.completion.contains('setState(');
      },
    );

    assertResponse(expected);
  }
}

mixin CatchClauseTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inCatchClause() async {
    await computeSuggestions('''
void f() {try {} catch (e) {^}}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  rethrow
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_inCatchClause_partial() async {
    await computeSuggestions('''
void f() {try {} catch (e) {r^}}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  return
    kind: keyword
  rethrow
    kind: keyword
''');
  }
}

mixin DoStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {do {^} while (true);}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {do {^} while (true);}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }
}

mixin ForStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {for (int x in myList) {^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_inFunction_withPatternVariables_for() async {
    await computeSuggestions('''
void f() {
  int a0 = 5;
  int b0 = 5;

  for (var (int a1, :b1) = g(); a1 > 0; a1--) {
    ^
  }
}

(int, {int b1}) g() => (1, b1: 2);
''');
    assertResponse(r'''
suggestions
  a1
    kind: localVariable
  b1
    kind: localVariable
  b0
    kind: localVariable
  a0
    kind: localVariable
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_inFunction_withPatternVariables_forEach() async {
    await computeSuggestions('''
void f() {
  int a0 = 5;
  int b0 = 5;

  for (var (int a1, :b1) in g()) {
    ^
  }
}

List<(int, {int b1})> g() => [(1, b1: 2)];
''');
    assertResponse(r'''
suggestions
  a1
    kind: localVariable
  b1
    kind: localVariable
  b0
    kind: localVariable
  a0
    kind: localVariable
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {for (int x in myList) {^}}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }
}

mixin FunctionBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterBlock_beforeRightBrace() async {
    await computeSuggestions('''
void f() {{}^}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterIf_beforeExpressionStatement() async {
    await computeSuggestions('''
void f() { if (true) {} ^ print(0); }
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterIfWithoutElse_beforeAwait_partial() async {
    await computeSuggestions('''
void f(int e01) async {
  if (false) {}
  e^
  await 0;
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  e01
    kind: parameter
  else
    kind: keyword
''');
  }

  Future<void> test_afterIfWithoutElse_beforeRightBrace() async {
    await computeSuggestions('''
void f() { if (true) {} ^ }
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_assert_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {assert^}
''');
    assertResponse(r'''
replacement
  left: 6
suggestions
  assert
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_do_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {do^}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  do
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_for_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {for^}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  for
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_if_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {if^}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  if
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_switch_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {switch^}
''');
    assertResponse(r'''
replacement
  left: 6
suggestions
  switch
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_try_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {try^}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  try
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_while_beforeRightBrace_partial() async {
    await computeSuggestions('''
void f() {while^}
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeIdentifier_withAsyncStar_partial() async {
    await computeSuggestions('''
void f() async* {n^ foo}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
void f() {^}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAssignment() async {
    allowedIdentifiers = {'foo'};
    newFile('$testPackageLibPath/a.dart', '''
int? foo(int? value) => value;
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  var total = f^();
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  foo
    kind: functionInvocation
  false
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
void f() async {^}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  await
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withAsyncStar_partial() async {
    await computeSuggestions('''
void f() async* {n^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withImportedTopLevelFunctionInvocation() async {
    allowedIdentifiers = {'wrapper'};
    newFile('$testPackageLibPath/a.dart', '''
String? wrapper(String? value) => value;
''');
    await computeSuggestions('''
import 'a.dart';

class A {
  final String? first;
  const A(this.first);
}

void f() {
  A(w^())
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  wrapper
    kind: functionInvocation
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withImportedTopLevelFunctions() async {
    allowedIdentifiers = {'aa0', 'aa1234'};
    newFile('$testPackageLibPath/a.dart', '''
void aa0(){}
void aa1234(){}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {aa^();}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  aa0
    kind: functionInvocation
  aa1234
    kind: functionInvocation
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withRecordLiteral() async {
    allowedIdentifiers = {'foo'};
    newFile('$testPackageLibPath/a.dart', '''
int? foo(int? value) => value;
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  var record = ('test', f^());
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
  foo
    kind: functionInvocation
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withSyncStar_partial() async {
    await computeSuggestions('''
void f() sync* {n^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }
}

mixin FunctionExpressionBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFieldInitializer() async {
    await computeSuggestions('''
class A {
  var f = () {^};
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_inInitializerList() async {
    await computeSuggestions('''
foo(p) {}
class A {
  final f;
  A() : f = foo(() {^});
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
foo(p) {}
class A {
  final f;
  A() : f = foo(() async {^});
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  await
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsyncStar() async {
    await computeSuggestions('''
  foo(p) {}
  class A {
    final f;
    A() : f = foo(() async* {^});
  }
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  await
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  yield
    kind: keyword
  yield*
    kind: keyword
''');
  }
}

mixin LocalFunctionBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
class A {
  m() {
    f() {^};
  }
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_nested() async {
    await computeSuggestions('''
class A {
  m() {
    f() {
      f2() {^};
    };
  }
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  f2
    kind: functionInvocation
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
class A {
  m() {
    f() {
      f2() async {^};
    };
  }
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  f2
    kind: functionInvocation
  var
    kind: keyword
  await
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsyncStar() async {
    await computeSuggestions('''
  class A {
    m() {
      f() {
        f2() async* {^};
      };
    }
  }

''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  f2
    kind: functionInvocation
  var
    kind: keyword
  await
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  yield
    kind: keyword
  yield*
    kind: keyword
''');
  }
}

mixin MethodBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
class F0 { var f1; f2() {} }
class E0 extends F0 { var e1; e2() {} }
class I0 { int i1; i2() {} }
class M0 { var m1; int m2() {} }
class A0 extends E0 implements I0 with M0 {a() {^}}
''');
    // Part of the purpose of this test is to ensure that none of the top-level
    // names are duplicated.
    assertResponse(r'''
suggestions
  return
    kind: keyword
  e1
    kind: field
  i1
    kind: field
  m1
    kind: field
  f1
    kind: field
  if
    kind: keyword
  final
    kind: keyword
  A0
    kind: class
  E0
    kind: class
  F0
    kind: class
  I0
    kind: class
  M0
    kind: class
  e2
    kind: methodInvocation
  f2
    kind: methodInvocation
  i2
    kind: methodInvocation
  m2
    kind: methodInvocation
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  A0
    kind: constructorInvocation
  E0
    kind: constructorInvocation
  F0
    kind: constructorInvocation
  I0
    kind: constructorInvocation
  M0
    kind: constructorInvocation
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_classGetterShadowsTopLevelGetter() async {
    newFile('$testPackageLibPath/a.dart', '''
int get m0 => 1;

void set m0(int i) {}
''');
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
import 'a.dart';

class A {
  int get m0 => 1;

  void f() {
    m^;
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  m0
    kind: getter
    declaringType: A
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_macroGenerated_generatedClass() async {
    addMacros([declareTypesPhaseMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareTypesPhase('C0', 'class C0 {}')
class C {}

void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  C0
    kind: class
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  C0
    kind: constructorInvocation
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_macroGenerated_sameClass() async {
    addMacros([declareInTypeMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareInType('  void m0() {}')
class C {
  void m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  m0
    kind: methodInvocation
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_macroGenerated_supperClass() async {
    addMacros([declareInTypeMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareInType('  void m0() {}')
class B {}

class C extends B {
  void m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  m0
    kind: methodInvocation
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void>
      test_afterLeftBrace_beforeRightBrace_macroGenerated_unrelatedClass() async {
    addMacros([declareInTypeMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareInType('  C.c1();')
class C0 {}

void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  C0
    kind: class
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  C0.c1
    kind: constructorInvocation
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
class A { foo() async {^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  await
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsyncStar() async {
    await computeSuggestions('''
class A { foo() async* {^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  await
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
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
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  yield
    kind: keyword
  yield*
    kind: keyword
''');
  }
}

mixin WhileStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {while (true) {^}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {while (true) {^}}}
''');
    assertResponse(r'''
suggestions
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  super
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  this
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  break
    kind: keyword
  const
    kind: keyword
  continue
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
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }
}
