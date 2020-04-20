// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoolAssignmentRelevanceTest);
  });
}

@reflectiveTest
class BoolAssignmentRelevanceTest extends DartCompletionManagerTest {
  @failingTest
  Future<void> test_boolLiterals_imported() async {
    addTestSource('''
foo() {
  bool b;
  b = ^
}
''');
    await computeSuggestions();

    var trueSuggestion = suggestionWith(
        completion: 'true', kind: CompletionSuggestionKind.KEYWORD);

    var falseSuggestion = suggestionWith(
        completion: 'false', kind: CompletionSuggestionKind.KEYWORD);

    var boolFromEnvironment = suggestionWith(
        completion: 'bool.fromEnvironment',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);

    expect(
        trueSuggestion.relevance, greaterThan(boolFromEnvironment.relevance));
    expect(
        falseSuggestion.relevance, greaterThan(boolFromEnvironment.relevance));
  }

  /// These are 2 failing tests for http://dartbug.com/37907:
  /// "Suggest `false` above other results when autocompleting a bool setter"
  @failingTest
  Future<void> test_boolLiterals_local() async {
    addTestSource('''
foo() {
  bool b;
  b = ^
}
''');
    await computeSuggestions();

    var trueSuggestion = suggestionWith(
        completion: 'true', kind: CompletionSuggestionKind.KEYWORD);

    var falseSuggestion = suggestionWith(
        completion: 'false', kind: CompletionSuggestionKind.KEYWORD);

    var bLocalVar = suggestionWith(
        completion: 'b',
        element: ElementKind.LOCAL_VARIABLE,
        kind: CompletionSuggestionKind.INVOCATION);

    expect(trueSuggestion.relevance, greaterThan(bLocalVar.relevance));
    expect(falseSuggestion.relevance, greaterThan(bLocalVar.relevance));
  }
}
