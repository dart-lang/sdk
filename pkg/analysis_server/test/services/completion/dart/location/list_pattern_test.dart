// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListPatternTest1);
    defineReflectiveTests(ListPatternTest2);
  });
}

@reflectiveTest
class ListPatternTest1 extends AbstractCompletionDriverTest
    with ListPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ListPatternTest2 extends AbstractCompletionDriverTest
    with ListPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ListPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_element_first() async {
    await computeSuggestions('''
const c01 = 1;
var v01 = 2;
void f(Object o1) {
  const c11 = 3;
  var v11 = 4;
  switch (o1) {
    case <int>[^ c01, c11]:
  }
}
''');
    assertResponse('''
suggestions
  c01
    kind: topLevelVariable
  c11
    kind: localVariable
  o1
    kind: parameter
  v01
    kind: topLevelVariable
  v11
    kind: localVariable
''');
  }

  Future<void> test_element_last() async {
    await computeSuggestions('''
const c01 = 1;
var v01 = 2;
void f(Object o1) {
  const c11 = 3;
  var v11 = 4;
  switch (o1) {
    case <int>[c01, c11, ^]:
  }
}
''');
    assertResponse('''
suggestions
  c01
    kind: topLevelVariable
  c11
    kind: localVariable
  o1
    kind: parameter
  v01
    kind: topLevelVariable
  v11
    kind: localVariable
''');
  }

  Future<void> test_element_middle() async {
    await computeSuggestions('''
const c01 = 1;
var v01 = 2;
void f(Object o1) {
  const c11 = 3;
  var v11 = 4;
  switch (o1) {
    case <int>[c01, ^, c11]:
  }
}
''');
    assertResponse('''
suggestions
  c01
    kind: topLevelVariable
  c11
    kind: localVariable
  o1
    kind: parameter
  v01
    kind: topLevelVariable
  v11
    kind: localVariable
''');
  }

  Future<void> test_element_only() async {
    await computeSuggestions('''
const c01 = 1;
var v01 = 2;
void f(Object o1) {
  const c11 = 3;
  var v11 = 4;
  switch (o1) {
    case <int>[^]:
  }
}
''');
    assertResponse('''
suggestions
  c01
    kind: topLevelVariable
  c11
    kind: localVariable
  o1
    kind: parameter
  v01
    kind: topLevelVariable
  v11
    kind: localVariable
''');
  }
}
