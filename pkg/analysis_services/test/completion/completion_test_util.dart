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
import 'package:analysis_testing/abstract_context.dart';
import 'package:analysis_testing/mock_sdk.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

class AbstractCompletionTest extends AbstractContextTest {
  Index index;
  SearchEngineImpl searchEngine;
  CompletionComputer computer;
  String testFile = '/completionTest.dart';
  Source testSource;
  int completionOffset;
  List<CompletionSuggestion> suggestions;
  bool _computeFastCalled = false;

  void addResolvedUnit(String file, String code) {
    Source source = addSource(file, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    index.indexUnit(context, unit);
  }

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    testSource = addSource(testFile, content);
  }

  void assertNotSuggested(String completion) {
    if (suggestions.any((cs) => cs.completion == completion)) {
      fail('did not expect completion: $completion');
    }
  }

  void assertSuggest(CompletionSuggestionKind kind, String completion,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT, bool isDeprecated
      = false, bool isPotential = false]) {
    var cs;
    suggestions.forEach((s) {
      if (s.completion == completion) {
        if (cs == null) {
          cs = s;
        } else {
          fail('expected exactly one $completion but found > 1');
        }
      }
    });
    if (cs == null) {
      var completions = suggestions.map((s) => s.completion).toList();
      fail('expected "$completion" but found\n $completions');
    }
    expect(cs.kind, equals(kind));
    expect(cs.relevance, equals(relevance));
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
  }

  void assertSuggestClass(String className, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.CLASS, className, relevance);
  }

  void assertSuggestField(String completion, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.FIELD, completion, relevance);
  }

  void assertSuggestFunction(String completion, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.FUNCTION, completion, relevance);
  }

  void assertSuggestLibraryPrefix(String completion,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    assertSuggest(
        CompletionSuggestionKind.LIBRARY_PREFIX,
        completion,
        relevance);
  }

  void assertSuggestMethodName(String completion, [CompletionRelevance relevance
      = CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.METHOD_NAME, completion, relevance);
  }

  void assertSuggestParameter(String completion, [CompletionRelevance relevance
      = CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.PARAMETER, completion, relevance);
  }

  void assertSuggestTopLevelVar(String completion,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    assertSuggest(
        CompletionSuggestionKind.TOP_LEVEL_VARIABLE,
        completion,
        relevance);
  }

  void assertSuggestVariable(String completion, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    assertSuggest(CompletionSuggestionKind.VARIABLE, completion, relevance);
  }

  bool computeFast() {
    _computeFastCalled = true;
    computer
        ..context = context
        ..searchEngine = searchEngine
        ..source = testSource
        ..offset = completionOffset;
    suggestions = [];
    CompilationUnit unit = context.parseCompilationUnit(testSource);
    return computer.computeFast(unit, suggestions);
  }

  Future<bool> computeFull() {
    if (!_computeFastCalled) {
      expect(computeFast(), isFalse);
    }
    var result = context.performAnalysisTask();
    while (result.hasMoreWork) {
      result.changeNotices.forEach((ChangeNotice notice) {
        CompilationUnit unit = notice.compilationUnit;
        if (unit != null) {
          index.indexUnit(context, unit);
        }
      });
      result = context.performAnalysisTask();
    }
    LibraryElement library = context.getLibraryElement(testSource);
    expect(library, isNotNull);
    var unit = context.getResolvedCompilationUnit(testSource, library);
    expect(unit, isNotNull);
    return computer.computeFull(unit, suggestions);
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    addResolvedUnit(MockSdk.LIB_CORE.path, MockSdk.LIB_CORE.content);
  }
}
