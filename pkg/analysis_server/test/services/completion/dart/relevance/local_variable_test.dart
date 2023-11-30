// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableTest1);
    defineReflectiveTests(LocalVariableTest2);
  });
}

@reflectiveTest
class LocalVariableTest1 extends CompletionRelevanceTest
    with LocalVariableTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LocalVariableTest2 extends CompletionRelevanceTest
    with LocalVariableTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  Future<void> test_localVariable_vs_importedClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class FooBarClass {}
''');

    await addTestFile('''
import 'a.dart';

int f() {
  final fooBar = 0;
  fBa^
}
''');

    assertOrder([
      suggestionWith(
        completion: 'fooBar',
        kind: CompletionSuggestionKind.IDENTIFIER,
      ),
      suggestionWith(
        completion: 'FooBarClass',
        kind: CompletionSuggestionKind.IDENTIFIER,
      ),
    ]);
  }
}

mixin LocalVariableTestCases on CompletionRelevanceTest {
  Future<void> test_localVariables() async {
    await addTestFile('''
int f() {
  var a = 0;
  var b = 1;
  var c = 2;
  var d = ^;
}
''');

    assertOrder([
      suggestionWith(
          completion: 'c',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.IDENTIFIER),
      suggestionWith(
          completion: 'b',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.IDENTIFIER),
      suggestionWith(
          completion: 'a',
          element: ElementKind.LOCAL_VARIABLE,
          kind: CompletionSuggestionKind.IDENTIFIER),
    ]);
  }
}
