// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.util;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

class AbstractCompletionTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;
  CompletionComputer _computer;
  int completionOffset;
  List<CompletionSuggestion> suggestions;

  get computer => _computer;

  set computer(CompletionComputer computer) {
    _computer = computer
        ..context = context
        ..searchEngine = searchEngine
        ..source = testSource
        ..offset = completionOffset;
  }

  void addTestUnit(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    resolveTestUnit(content);
    index.indexUnit(context, testUnit);
  }

  void addUnit(String file, String code) {
    Source source = addSource(file, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    assertNoErrorsInSource(source);
    index.indexUnit(context, unit);
  }

  void assertClassResult(String className, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertHasResult(CompletionSuggestionKind.CLASS, className, relevance);
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT, bool isDeprecated
      = false, bool isPotential = false]) {
    var cs =
        suggestions.firstWhere((cs) => cs.completion == completion, orElse: () {
      var completions = suggestions.map((s) => s.completion).toList();
      fail('expected "$completion" but found\n $completions');
    });
    expect(cs.kind, equals(kind));
    expect(cs.relevance, equals(relevance));
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
  }

  void assertNoResult(String completion) {
    if (suggestions.any((cs) => cs.completion == completion)) {
      fail('did not expect completion: $completion');
    }
  }

  void assertTopLevelVarResult(String varName, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertHasResult(
        CompletionSuggestionKind.TOP_LEVEL_VARIABLE,
        varName,
        relevance);
  }

  bool computeFast() {
    if (suggestions == null) suggestions = [];
    return computer.computeFast(testUnit, suggestions);
  }

  Future<bool> computeFull() {
    if (suggestions == null) suggestions = [];
    return computer.computeFull(testUnit, suggestions);
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    verifyNoTestUnitErrors = false;
    addUnit(MockSdk.LIB_CORE.path, MockSdk.LIB_CORE.content);
  }
}
