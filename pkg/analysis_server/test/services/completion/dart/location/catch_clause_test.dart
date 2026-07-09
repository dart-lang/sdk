// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternTest);
  });
}

@reflectiveTest
class CastPatternTest extends AbstractCompletionDriverTest
    with CastPatternTestCases {}

mixin CastPatternTestCases on AbstractCompletionDriverTest {
  @failingTest
  Future<void> test_exception() async {
    await computeSuggestions('''
void f(Object x) {
  try {} catch (^) {}
}
''');
    assertResponse(r'''
suggestions
  e
    kind: identifier
  exception
    kind: identifier
''');
  }

  @failingTest
  Future<void> test_exception_partial() async {
    await computeSuggestions('''
void f(Object x) {
  try {} catch (e^) {}
}
''');
    assertResponse(r'''
suggestions
  e
    kind: identifier
  exception
    kind: identifier
''');
  }

  @failingTest
  Future<void> test_stackTrace() async {
    await computeSuggestions('''
void f(Object x) {
  try {} catch (e, ^) {}
}
''');
    assertResponse(r'''
suggestions
  st
    kind: identifier
  stackTrace
    kind: identifier
''');
  }

  @failingTest
  Future<void> test_stackTrace_partial() async {
    await computeSuggestions('''
void f(Object x) {
  try {} catch (e, s^) {}
}
''');
    assertResponse(r'''
suggestions
  st
    kind: identifier
  stackTrace
    kind: identifier
''');
  }
}
