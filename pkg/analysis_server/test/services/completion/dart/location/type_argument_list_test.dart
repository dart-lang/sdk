// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeArgumentListTest);
  });
}

@reflectiveTest
class TypeArgumentListTest extends AbstractCompletionDriverTest
    with TypeArgumentListTestCases {}

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
  void
    kind: keyword
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterLess_beforeGreater_namedType() async {
    await computeSuggestions('''
void m() {List<^> list;}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterLess_beforeGreater_topLevel() async {
    await computeSuggestions('''
class A01 {}

Future<^>
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  void
    kind: keyword
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterLess_beforeGreater_topLevel_partial() async {
    await computeSuggestions('''
class A01 {}

Future<A0^>
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void>
  test_afterLess_beforeGreater_topLevel_withVariableName_partial() async {
    await computeSuggestions('''
Future<v^> x
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
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
  void
    kind: keyword
  dynamic
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
  void
    kind: keyword
  dynamic
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
  void
    kind: keyword
  dynamic
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
  void
    kind: keyword
  dynamic
    kind: keyword
''');
  }
}
