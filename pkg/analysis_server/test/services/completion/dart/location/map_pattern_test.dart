// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapPatternTest1);
    defineReflectiveTests(MapPatternTest2);
  });
}

@reflectiveTest
class MapPatternTest1 extends AbstractCompletionDriverTest
    with MapPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class MapPatternTest2 extends AbstractCompletionDriverTest
    with MapPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin MapPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_entry_key_assignmentContext_middle() async {
    await computeSuggestions('''
void f(Map<String, int> m1) {
  const c1 = '3';
  var v1 = '4';
  final {c1 : 1, ^, c1 : 3} = m1;
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  m1
    kind: parameter
  null
    kind: keyword
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_assignmentContext_only() async {
    await computeSuggestions('''
void f(Map<String, int> m1) {
  const c1 = '3';
  var v1 = '4';
  final {^} = m1;
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  m1
    kind: parameter
  null
    kind: keyword
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_first() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{^ c1 : 1, c1 : 3]:
  }
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_last() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c1 : 1, c1 : 3, ^}:
  }
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_middle() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c1 : 1, ^, c1 : 3}:
  }
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_middle_partial() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c1 : 1, c^, c1 : 3}:
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
    }
  }

  Future<void> test_entry_key_only() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{^}:
  }
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
  }

  Future<void> test_entry_key_only_partial() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c^}:
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
''');
    }
  }

  Future<void> test_entry_value() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c1 : ^}:
  }
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
  var
    kind: keyword
''');
  }

  Future<void> test_entry_value_partial() async {
    await computeSuggestions('''
void f(Object o1) {
  const c1 = '3';
  var v1 = '4';
  switch (o1) {
    case <String, int>{c1 : v^}:
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  v1
    kind: localVariable
  var
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  c1
    kind: localVariable
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  o1
    kind: parameter
  true
    kind: keyword
  v1
    kind: localVariable
  var
    kind: keyword
''');
    }
  }
}
