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

  @FailingTest(
      issue: 'https://github.com/dart-lang/sdk/issues/54773',
      reason: 'The parser recovers by assuming that this is a '
          'function declaration of the form `Future<v>() {}`.')
  Future<void> test_afterLess_beforeGreater_topLevel_partial() async {
    // TODO(brianwilkerson): Either
    //  - change the parser's recovery so that it produces a top-level variable
    //    of the form `Function<v> s;` (where `s` is a synthetic identifier), or
    //  - add logic to InScopeCompletionPass.visitTypeParameter to detect this
    //    case and treat it like a completion in a type argument list.
    await computeSuggestions('''
Future<v^>
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  void
    kind: keyword
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
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }
}
