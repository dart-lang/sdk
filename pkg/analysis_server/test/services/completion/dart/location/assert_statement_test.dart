// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertStatementTest);
  });
}

@reflectiveTest
class AssertStatementTest extends AbstractCompletionDriverTest {
  Future<void> test_condition() async {
    await computeSuggestions('''
void f(int v01) {
  assert(^);
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertStatement_condition
locationOpType: AssertStatement_condition
suggestions
  v01
    kind: parameter
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_condition_hasMessage() async {
    await computeSuggestions('''
void f(int v01) {
  assert(^, '');
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertStatement_condition
locationOpType: AssertStatement_condition
suggestions
  v01
    kind: parameter
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_message() async {
    await computeSuggestions('''
void f(int v01) {
  assert(true, ^);
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertStatement_condition
suggestions
  v01
    kind: parameter
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }
}
