// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlockTest1);
    defineReflectiveTests(BlockTest2);
  });
}

@reflectiveTest
class BlockTest1 extends AbstractCompletionDriverTest
    with
        BlockTestCases,
        CatchClauseTestCases,
        FunctionBodyTestCases,
        DoStatementTestCases,
        ForStatementTestCases,
        MethodBodyTestCases,
        FunctionExpressionBodyTestCases,
        LocalFunctionBodyTestCases,
        WhileStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class BlockTest2 extends AbstractCompletionDriverTest
    with
        BlockTestCases,
        CatchClauseTestCases,
        FunctionBodyTestCases,
        DoStatementTestCases,
        ForStatementTestCases,
        MethodBodyTestCases,
        FunctionExpressionBodyTestCases,
        LocalFunctionBodyTestCases,
        WhileStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

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
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  rethrow
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
}

mixin DoStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {do {^} while (true);}
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {do {^} while (true);}}
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
}

mixin ForStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeRightBrace_inFunction() async {
    await computeSuggestions('''
void f() {for (int x in myList) {^}}
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {for (int x in myList) {^}}}
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
}

mixin FunctionBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterBlock_beforeRightBrace() async {
    await computeSuggestions('''
void f() {{}^}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterIf_beforeExpressionStatement() async {
    await computeSuggestions('''
void f() { if (true) {} ^ print(0); }
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterIfWithoutElse_beforeRightBrace() async {
    await computeSuggestions('''
void f() { if (true) {} ^ }
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
      test_afterLeftBrace_beforeIdentifier_withAsyncStar_partial() async {
    await computeSuggestions('''
void f() async* {n^ foo}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
void f() {^}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
void f() async {^}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
      test_afterLeftBrace_beforeRightBrace_withAsyncStar_partial() async {
    await computeSuggestions('''
void f() async* {n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withSyncStar_partial() async {
    await computeSuggestions('''
void f() sync* {n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f2
    kind: functionInvocation
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f2
    kind: functionInvocation
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  f2
    kind: functionInvocation
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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
class A { foo() {^}}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsync() async {
    await computeSuggestions('''
class A { foo() async {^}}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_withAsyncStar() async {
    await computeSuggestions('''
class A { foo() async* {^}}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
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

  Future<void> test_afterLeftBrace_beforeRightBrace_inMethod() async {
    await computeSuggestions('''
class A {foo() {while (true) {^}}}
''');
    assertResponse(r'''
suggestions
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
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  throw
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
}
