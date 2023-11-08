// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementTest1);
    defineReflectiveTests(TryStatementTest2);
  });
}

@reflectiveTest
class TryStatementTest1 extends AbstractCompletionDriverTest
    with TryStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class TryStatementTest2 extends AbstractCompletionDriverTest
    with TryStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin TryStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCatchClause_beforeEnd_partial() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} c^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterCatchClause_beforeEnd_partial2() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} c^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterCatchClause_beforeEnd_withOn() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} ^}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterCatchClause_beforeEnd_withoutOn() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} ^}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterCatchClause_beforeSemicolon_withOn() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} ^;}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterCatchClause_beforeSemicolon_withoutOn() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} ^;}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterCatchClause_beforeVariableDeclaration_withOn() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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
      test_afterCatchClause_beforeVariableDeclaration_withoutOn() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterTryBlock_beforeCatch_partial() async {
    await computeSuggestions('''
void f() {try {} c^ catch (e) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterTryBlock_beforeCatchClause_withOn() async {
    await computeSuggestions('''
void f() {try {} ^ on SomeException {}}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  on
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeCatchClause_withoutOn() async {
    await computeSuggestions('''
void f() {try {} ^ catch (e) {}}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  on
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeEnd() async {
    await computeSuggestions('''
void f() {try {} ^}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeEnd_partial() async {
    await computeSuggestions('''
void f() {try {} c^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterTryBlock_beforeFinally_partial() async {
    await computeSuggestions('''
void f() {try {} c^ finally {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterTryBlock_beforeFinallyClause() async {
    await computeSuggestions('''
void f() {try {} ^ finally {}}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  on
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeOn_partial() async {
    // This is an odd test because the `catch` belongs after the `on` clause,
    // which makes it hard to know what the user might be trying to type.
    await computeSuggestions('''
void f() {try {} c^ on SomeException {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  const
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  finally
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  on
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

  Future<void> test_afterTryBlock_beforeSemicolon() async {
    await computeSuggestions('''
void f() {try {} ^;}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeVariableDeclaration() async {
    await computeSuggestions('''
void f() {try {} ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  catch
    kind: keyword
  finally
    kind: keyword
  on
    kind: keyword
''');
  }
}
