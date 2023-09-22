// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParameterListInConstructorTest1);
    defineReflectiveTests(ParameterListInConstructorTest2);
    defineReflectiveTests(ParameterListInFunctionTest1);
    defineReflectiveTests(ParameterListInFunctionTest2);
    defineReflectiveTests(ParameterListInMethodTest1);
    defineReflectiveTests(ParameterListInMethodTest2);
  });
}

@reflectiveTest
class ParameterListInConstructorTest1 extends AbstractCompletionDriverTest
    with ParameterListInConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ParameterListInConstructorTest2 extends AbstractCompletionDriverTest
    with ParameterListInConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ParameterListInConstructorTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftParen_beforeFunctionType() async {
    await computeSuggestions('''
class A { A(^ Function() f) {}}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
class A { A(^) {}}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_language215() async {
    await computeSuggestions('''
// @dart = 2.15
class A {
  A(^);
}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_partial() async {
    await computeSuggestions('''
class A { A(t^) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  this
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
    }
  }
}

@reflectiveTest
class ParameterListInFunctionTest1 extends AbstractCompletionDriverTest
    with ParameterListInFunctionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ParameterListInFunctionTest2 extends AbstractCompletionDriverTest
    with ParameterListInFunctionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ParameterListInFunctionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftParen_beforeFunctionType_partial() async {
    await computeSuggestions('''
void f(^void Function() g) {}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }
}

@reflectiveTest
class ParameterListInMethodTest1 extends AbstractCompletionDriverTest
    with ParameterListInMethodTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ParameterListInMethodTest2 extends AbstractCompletionDriverTest
    with ParameterListInMethodTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ParameterListInMethodTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterColon_beforeRightBrace() async {
    await computeSuggestions('''
class A { foo({bool bar: ^}) {}}
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

  Future<void> test_afterColon_beforeRightBrace_partial() async {
    await computeSuggestions('''
class A { foo({bool bar: f^}) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
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

  Future<void> test_afterEqual_beforeRightBracket() async {
    await computeSuggestions('''
class A { foo([bool bar = ^]) {}}
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

  Future<void> test_afterEqual_beforeRightBracket_partial() async {
    await computeSuggestions('''
class A { foo([bool bar = f^]) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
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

  Future<void> test_afterLeftParen_beforeFunctionType() async {
    await computeSuggestions('''
class A { foo(^ Function(){}) {}}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
class A { foo(^) {}}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_partial() async {
    await computeSuggestions('''
class A { foo(t^) {}}
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
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  void
    kind: keyword
''');
    }
  }
}
