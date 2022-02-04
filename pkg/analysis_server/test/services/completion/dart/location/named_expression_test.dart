// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedExpressionExpressionTest1);
    defineReflectiveTests(NamedExpressionExpressionTest2);
  });
}

@reflectiveTest
class NamedExpressionExpressionTest1 extends AbstractCompletionDriverTest
    with NamedExpressionExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class NamedExpressionExpressionTest2 extends AbstractCompletionDriverTest
    with NamedExpressionExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin NamedExpressionExpressionTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_beforePositional() async {
    var response = await getTestCodeSuggestions('''
void f(int x) {
  g(b: ^, 0);
}

void g(int a, {required int b}) {}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('x')
          ..isParameter,
      ]);
  }

  Future<void> test_lastArgument() async {
    var response = await getTestCodeSuggestions('''
void f(int x) {
  g(0, b: ^);
}

void g(int a, {required int b}) {}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('x')
          ..isParameter,
      ]);
  }

  Future<void> test_onlyArgument() async {
    var response = await getTestCodeSuggestions('''
void f(int x) {
  g(a: ^);
}

void g({required int a}) {}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.includesAll([
        (suggestion) => suggestion
          ..completion.isEqualTo('x')
          ..isParameter,
      ]);
  }
}
