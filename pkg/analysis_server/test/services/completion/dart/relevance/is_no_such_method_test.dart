// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsNoSuchMethodTest1);
    defineReflectiveTests(IsNoSuchMethodTest2);
  });
}

@reflectiveTest
class IsNoSuchMethodTest1 extends CompletionRelevanceTest
    with IsNoSuchMethodTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class IsNoSuchMethodTest2 extends CompletionRelevanceTest
    with IsNoSuchMethodTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin IsNoSuchMethodTestCases on CompletionRelevanceTest {
  Future<void> test_notSuper() async {
    await addTestFile('''
void foo(Object o) {
  o.^;
}
''');

    var toStringSuggestion = suggestionWith(
        completion: 'toString',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    var noSuchMethodSuggestion = suggestionWith(
        completion: 'noSuchMethod',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    assertOrder([toStringSuggestion, noSuchMethodSuggestion]);
  }

  Future<void> test_super() async {
    await addTestFile('''
class C {
  dynamic noSuchMethod(Invocation i) => super.^;
}
''');

    var toStringSuggestion = suggestionWith(
        completion: 'toString',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    var noSuchMethodSuggestion = suggestionWith(
        completion: 'noSuchMethod',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    assertOrder([noSuchMethodSuggestion, toStringSuggestion]);
  }
}
