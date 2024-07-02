// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionInvocationTest);
  });
}

@reflectiveTest
class FunctionInvocationTest extends AbstractCompletionDriverTest
    with FunctionInvocationTestCases {}

mixin FunctionInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_implicitCall() async {
    await computeSuggestions('''
extension E<T> on Comparator<T> {
  Comparator<T> get inverse => (T a0, T b0) => this(^);
}
''');
    // TODO(brianwilkerson): `super` should not be suggested here.
    assertResponse(r'''
suggestions
  a0
    kind: parameter
  b0
    kind: parameter
  true
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  this
    kind: keyword
  const
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
''');
  }
}
