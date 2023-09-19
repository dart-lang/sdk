// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeArgumentListTest1);
    defineReflectiveTests(TypeArgumentListTest2);
  });
}

@reflectiveTest
class TypeArgumentListTest1 extends AbstractCompletionDriverTest
    with TypeArgumentListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class TypeArgumentListTest2 extends AbstractCompletionDriverTest
    with TypeArgumentListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin TypeArgumentListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLess_beforeGreater_functionInvocation() async {
    await computeSuggestions('''
void f<T>() {}

void m() {
  f<^>();
}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLess_beforeGreater_namedType() async {
    await computeSuggestions('''
void m() {List<^> list;}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_argument_afterClassName() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case G<^>
  }
}

class A01 {}
class A02 {}
class B01 {}
class G<T> {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_argument_emptyList() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case <^>[]
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
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_argument_emptyMap() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case <^>{}
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
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_argument_lessThanAndGreaterThan() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case <^>
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
  A02
    kind: class
  B01
    kind: class
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
