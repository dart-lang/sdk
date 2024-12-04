// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoolAssignmentTest);
  });
}

@reflectiveTest
class BoolAssignmentTest extends CompletionRelevanceTest
    with BoolAssignmentTestCases {
  @FailingTest(
    reason: r'''
The actual relevances are:
[completion: bool.fromEnvironment][relevance: 591]
[completion: bool.hasEnvironment][relevance: 591]
[completion: b][relevance: 587]
[completion: bool][relevance: 578]
[completion: true][relevance: 574]
[completion: false][relevance: 572]
[completion: identical][relevance: 563]
  for (var e in result) {
    print('[completion: ${e.completion}][relevance: ${e.relevance}]');
  }
''',
  )
  @override
  Future<void> test_boolLiterals_imported() {
    // TODO(scheglov): implement test_boolLiterals_imported
    return super.test_boolLiterals_imported();
  }
}

mixin BoolAssignmentTestCases on CompletionRelevanceTest {
  Future<void> test_boolLiterals_imported() async {
    await addTestFile('''
foo() {
  bool b;
  b = ^
}
''');

    var trueSuggestion = suggestionWith(
      completion: 'true',
      kind: CompletionSuggestionKind.KEYWORD,
    );

    var falseSuggestion = suggestionWith(
      completion: 'false',
      kind: CompletionSuggestionKind.KEYWORD,
    );

    var boolFromEnvironment = suggestionWith(
      completion: 'bool.fromEnvironment',
      element: ElementKind.CONSTRUCTOR,
      kind: CompletionSuggestionKind.INVOCATION,
    );

    assertOrder([trueSuggestion, falseSuggestion, boolFromEnvironment]);
  }

  Future<void> test_boolLiterals_local() async {
    await addTestFile('''
foo() {
  bool b;
  b = ^
}
''');

    var trueSuggestion = suggestionWith(
      completion: 'true',
      kind: CompletionSuggestionKind.KEYWORD,
    );

    var falseSuggestion = suggestionWith(
      completion: 'false',
      kind: CompletionSuggestionKind.KEYWORD,
    );

    var bLocalVar = suggestionWith(
      completion: 'b',
      element: ElementKind.LOCAL_VARIABLE,
      kind: CompletionSuggestionKind.IDENTIFIER,
    );

    assertOrder([bLocalVar, trueSuggestion, falseSuggestion]);
  }
}
