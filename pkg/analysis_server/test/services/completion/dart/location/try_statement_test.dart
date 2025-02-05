// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementTest);
  });
}

@reflectiveTest
class TryStatementTest extends AbstractCompletionDriverTest
    with TryStatementTestCases {}

mixin TryStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCatchClause_beforeEnd_partial() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} c^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  const
    kind: keyword
''');
  }

  Future<void> test_afterCatchClause_beforeEnd_partial2() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} c^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
  const
    kind: keyword
''');
  }

  Future<void> test_afterCatchClause_beforeEnd_withOn() async {
    await computeSuggestions('''
void f() {try {} on SomeException {} ^}
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
    kind: keyword
  true
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
    kind: keyword
  true
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
    kind: keyword
  true
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
    kind: keyword
  true
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
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
  test_afterCatchClause_beforeVariableDeclaration_withoutOn() async {
    await computeSuggestions('''
void f() {try {} catch (e) {} ^ Foo foo;}
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
  catch
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  finally
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  on
    kind: keyword
  true
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
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
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
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
  }

  Future<void> test_afterTryBlock_beforeFinally_partial() async {
    await computeSuggestions('''
void f() {try {} c^ finally {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
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
    // What the user is likely trying to do is add a new clause before the `on`,
    // in which case we shouldn't be suggesting `finally`, but the parser
    // produces a try statement with no clauses, followed by a variable
    // declaration statement (`c on;`), so we can't see that there's already a
    // `catch` clause.
    await computeSuggestions('''
void f() {try {} c^ on SomeException {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  catch
    kind: keyword
''');
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
