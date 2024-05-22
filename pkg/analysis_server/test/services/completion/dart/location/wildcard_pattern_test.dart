// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WildcardPatternTest);
  });
}

@reflectiveTest
class WildcardPatternTest extends AbstractCompletionDriverTest
    with WildcardPatternTestCases {}

mixin WildcardPatternTestCases on AbstractCompletionDriverTest {
  void test_ifCase_type() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case ^ _) {}
}

class A01 {}
class A02 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
''');
  }

  void test_ifCase_type_partial() async {
    await computeSuggestions('''
void f(Object? x) {
  if (x case A0^ _) {}
}

class A01 {}
class A02 {}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A02
    kind: class
''');
  }

  void test_switchPatternCase_type() async {
    await computeSuggestions('''
void f(Object? x) {
  switch (x) {
    case ^ _:
      break;
  }
}

class A01 {}
class A02 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
''');
  }

  void test_switchPatternCase_type_partial() async {
    await computeSuggestions('''
void f(Object? x) {
  switch (x) {
    case A0^ _:
      break;
  }
}

class A01 {}
class A02 {}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
  A02
    kind: class
''');
  }
}
