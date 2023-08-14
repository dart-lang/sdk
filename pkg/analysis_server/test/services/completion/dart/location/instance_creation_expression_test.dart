// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationExpressionTest1);
    defineReflectiveTests(InstanceCreationExpressionTest2);
  });
}

@reflectiveTest
class InstanceCreationExpressionTest1 extends AbstractCompletionDriverTest
    with InstanceCreationExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class InstanceCreationExpressionTest2 extends AbstractCompletionDriverTest
    with InstanceCreationExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin InstanceCreationExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterNew_beforeEnd() async {
    await computeSuggestions('''
class A { foo() {new ^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterNew_beforeStatement() async {
    await computeSuggestions('''
class A { foo() {new ^ print("foo");}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterPeriod_beforeEnd() async {
    await computeSuggestions('''
void f() {new Future.^}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterPeriod_beforeEnd_prefixed() async {
    await computeSuggestions('''
class A { foo() {new A.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterPeriod_beforeStatement_prefixed() async {
    await computeSuggestions('''
class A { foo() {new A.^ print("foo");}}
''');
    assertResponse(r'''
suggestions
''');
  }
}
