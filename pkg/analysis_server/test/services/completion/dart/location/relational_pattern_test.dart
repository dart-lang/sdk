// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternTest1);
    defineReflectiveTests(RelationalPatternTest2);
  });
}

@reflectiveTest
class RelationalPatternTest1 extends AbstractCompletionDriverTest
    with RelationalPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class RelationalPatternTest2 extends AbstractCompletionDriverTest
    with RelationalPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin RelationalPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_argument_greaterThanOrEqual_partial() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case >= A^
  }
}

class A01 {}
class A02 {}
class B01 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
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
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: class
  A02
    kind: constructorInvocation
  B01
    kind: class
  B01
    kind: constructorInvocation
  const
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_argument_lessThan() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case <^
  }
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: class
  A02
    kind: constructorInvocation
  B01
    kind: class
  B01
    kind: constructorInvocation
  const
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
''');
  }
}
