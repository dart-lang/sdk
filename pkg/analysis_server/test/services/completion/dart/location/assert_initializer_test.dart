// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertInitializerTest);
  });
}

@reflectiveTest
class AssertInitializerTest extends AbstractCompletionDriverTest {
  Future<void> test_condition() async {
    await computeSuggestions('''
class A {
  A(int v01) : assert(^);
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertInitializer_condition
locationOpType: AssertInitializer_condition
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
class A {
  A(int v01) : assert(^, '');
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertInitializer_condition
locationOpType: AssertInitializer_condition
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
class A {
  A(int v01) : assert(true, ^);
}
''');
    printerConfiguration.withLocationName = true;
    assertResponse(r'''
location: AssertInitializer_condition
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
