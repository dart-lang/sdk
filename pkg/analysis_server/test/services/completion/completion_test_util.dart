// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.util;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';

class AbstractCompletionTest extends AbstractContextTest {
  Index index;
  SearchEngineImpl searchEngine;
  DartCompletionComputer computer;
  String testFile = '/completionTest.dart';
  Source testSource;
  int completionOffset;
  bool _computeFastCalled = false;
  DartCompletionRequest request;

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
    request =
        new DartCompletionRequest(context, searchEngine, testSource, completionOffset);
  }

  void assertNotSuggested(String completion) {
    if (request.suggestions.any((cs) => cs.completion == completion)) {
      fail('did not expect completion: $completion');
    }
  }

  CompletionSuggestion assertSuggest(CompletionSuggestionKind kind,
      String completion, [CompletionRelevance relevance = CompletionRelevance.DEFAULT,
      bool isDeprecated = false, bool isPotential = false]) {
    CompletionSuggestion cs;
    request.suggestions.forEach((s) {
      if (s.completion == completion) {
        if (cs == null) {
          cs = s;
        } else {
          List<CompletionSuggestion> matchSuggestions =
              request.suggestions.where((s) => s.completion == completion).toList();
          fail(
              'expected exactly one $completion but found > 1\n $matchSuggestions');
        }
      }
    });
    if (cs == null) {
      List<CompletionSuggestion> completions =
          request.suggestions.map((s) => s.completion).toList();
      fail('expected "$completion" but found\n $completions');
    }
    expect(cs.kind, equals(kind));
    expect(cs.relevance, equals(relevance));
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    return cs;
  }

  CompletionSuggestion assertSuggestClass(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.CLASS, name, relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(name));
    expect(element.returnType, isNull);
    return cs;
  }

  CompletionSuggestion assertSuggestFunction(String name, String returnType,
      bool isDeprecated, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs = assertSuggest(
        CompletionSuggestionKind.FUNCTION,
        name,
        relevance,
        isDeprecated);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestGetter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.GETTER, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.GETTER));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestLibraryPrefix(String prefix,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.LIBRARY_PREFIX, prefix, relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LIBRARY));
    expect(element.name, equals(prefix));
    expect(element.returnType, isNull);
    return cs;
  }

  CompletionSuggestion assertSuggestLocalVariable(String name,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.LOCAL_VARIABLE, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LOCAL_VARIABLE));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestMethod(String name, String declaringType,
      String returnType, [CompletionRelevance relevance =
      CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.METHOD, name, relevance);
    expect(cs.declaringType, equals(declaringType));
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.METHOD));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestParameter(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.PARAMETER, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.PARAMETER));
    expect(element.name, equals(name));
    expect(
        element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  CompletionSuggestion assertSuggestSetter(String name,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.SETTER, name, relevance);
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.SETTER));
    expect(element.name, equals(name));
    expect(element.returnType, isNull);
    return cs;
  }

  CompletionSuggestion assertSuggestTopLevelVar(String name, String returnType,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    CompletionSuggestion cs =
        assertSuggest(CompletionSuggestionKind.TOP_LEVEL_VARIABLE, name, relevance);
    expect(cs.returnType, equals(returnType));
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.TOP_LEVEL_VARIABLE));
    expect(element.name, equals(name));
    //TODO (danrubel) return type level variable 'type' but not as 'returnType'
//    expect(
//        element.returnType,
//        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  bool computeFast() {
    _computeFastCalled = true;
    CompilationUnit unit = context.parseCompilationUnit(testSource);
    request.unit = unit;
    request.node = new NodeLocator.con1(completionOffset).searchWithin(unit);
    return computer.computeFast(request);
  }

  Future<bool> computeFull([bool fullAnalysis = false]) {
    if (!_computeFastCalled) {
      expect(computeFast(), isFalse);
    }

    // Index SDK
    for (Source librarySource in context.librarySources) {
      CompilationUnit unit =
          context.getResolvedCompilationUnit2(librarySource, librarySource);
      if (unit != null) {
        index.indexUnit(context, unit);
      }
    }

    var result = context.performAnalysisTask();
    bool resolved = false;
    while (result.hasMoreWork) {

      // Update the index
      result.changeNotices.forEach((ChangeNotice notice) {
        CompilationUnit unit = notice.compilationUnit;
        if (unit != null) {
          index.indexUnit(context, unit);
        }
      });

      // If the unit has been resolved, then finish the completion
      LibraryElement library = context.getLibraryElement(testSource);
      if (library != null) {
        CompilationUnit unit =
            context.getResolvedCompilationUnit(testSource, library);
        if (unit != null) {
          request.unit = unit;
          request.node =
              new NodeLocator.con1(completionOffset).searchWithin(unit);
          resolved = true;
          if (!fullAnalysis) {
            break;
          }
        }
      }

      result = context.performAnalysisTask();
    }
    if (!resolved) {
      fail('expected unit to be resolved');
    }
    return computer.computeFull(request);
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }
}
