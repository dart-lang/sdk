// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElementTest);
    defineReflectiveTests(IfElementInListTest);
    defineReflectiveTests(IfElementInMapTest);
    defineReflectiveTests(IfElementInSetTest);
  });
}

@reflectiveTest
class IfElementInListTest extends AbstractCompletionDriverTest
    with IfElementInListTestCases {}

mixin IfElementInListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterElse_beforeComma_partial() async {
    await computeSuggestions('''
void f(int i) {
  [if (true) 1 else 2 e^, i, i];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterElse_beforeEnd() async {
    await computeSuggestions('''
f() => [if (true) 1 else ^];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterFor_beforeEnd_partial() async {
    await computeSuggestions('''
void f(int i) {
  [if (b) for (var e in c) e e^];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeEnd() async {
    await computeSuggestions('''
f() => [if (true) ^];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeComma() async {
    await computeSuggestions('''
void f(int i, int j) {
  [if (true) i ^, j];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeComma_partial_list() async {
    await computeSuggestions('''
void f(int i) {
  [if (true) 1 e^, i];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeEnd() async {
    await computeSuggestions('''
void f(int i) {
  [if (true) i ^];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeEnd_nestedInElse() async {
    await computeSuggestions('''
void f(int i) {
  [if (false) i else if (true) i ^];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeEnd_nestedInFor() async {
    await computeSuggestions('''
void f(int i) {
  [for (var e in []) if (true) i ^];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterThen_beforeEnd_nestedInThen() async {
    await computeSuggestions('''
void f(int i) {
  [if (false) if (true) i ^];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  else
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_test_afterThen_beforeEnd_partial() async {
    await computeSuggestions('''
void f() {
  [if (true) 1 e^];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }
}

@reflectiveTest
class IfElementInMapTest extends AbstractCompletionDriverTest
    with IfElementInMapTestCases {}

mixin IfElementInMapTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterMapEntry_beforeComma_partial() async {
    await computeSuggestions('''
void f(int i) {
  <int, int>{if (true) 1: 1 e^, 2: i};
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }
}

@reflectiveTest
class IfElementInSetTest extends AbstractCompletionDriverTest
    with IfElementInSetTestCases {}

mixin IfElementInSetTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterThen_beforeComma_partial_set() async {
    await computeSuggestions('''
void f(int i) {
  <int>{if (true) 1 e^, i};
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  else
    kind: keyword
''');
  }
}

@reflectiveTest
class IfElementTest extends AbstractCompletionDriverTest
    with IfElementTestCases {}

mixin IfElementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterPattern() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x ^) ];
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
  var v = [ if (o case var x w^) ];
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

  Future<void> test_afterWhen() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x when ^) ];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterWhen_partial() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x when c^) ];
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
var v = [ if (o ^) ];
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
var v = [ if (^) ];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }
}
