// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.util;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart'
    show DART_RELEVANCE_DEFAULT, DART_RELEVANCE_LOW, ReplacementRange;
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../../abstract_context.dart';

int suggestionComparator(CompletionSuggestion s1, CompletionSuggestion s2) {
  String c1 = s1.completion.toLowerCase();
  String c2 = s2.completion.toLowerCase();
  return c1.compareTo(c2);
}

abstract class DartCompletionContributorTest extends AbstractContextTest {
  Index index;
  SearchEngineImpl searchEngine;
  String testFile = '/completionTest.dart';
  Source testSource;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  DartCompletionContributor contributor;
  DartCompletionRequest request;
  List<CompletionSuggestion> suggestions;

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

  void assertHasParameterInfo(CompletionSuggestion suggestion) {
    expect(suggestion.parameterNames, isNotNull);
    expect(suggestion.parameterTypes, isNotNull);
    expect(suggestion.parameterNames.length, suggestion.parameterTypes.length);
    expect(suggestion.requiredParameterCount,
        lessThanOrEqualTo(suggestion.parameterNames.length));
    expect(suggestion.hasNamedParameters, isNotNull);
  }

  void assertNoSuggestions({CompletionSuggestionKind kind: null}) {
    if (kind == null) {
      if (suggestions.length > 0) {
        failedCompletion('Expected no suggestions', suggestions);
      }
      return;
    }
    CompletionSuggestion suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.kind == kind,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  void assertNotSuggested(String completion) {
    CompletionSuggestion suggestion = suggestions.firstWhere(
        (CompletionSuggestion cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  CompletionSuggestion assertSuggest(String completion,
      {CompletionSuggestionKind csKind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT,
      String importUri,
      protocol.ElementKind elemKind: null,
      bool isDeprecated: false,
      bool isPotential: false,
      String elemFile,
      int elemOffset}) {
    CompletionSuggestion cs =
        getSuggest(completion: completion, csKind: csKind, elemKind: elemKind);
    if (cs == null) {
      failedCompletion('expected $completion $csKind $elemKind', suggestions);
    }
    expect(cs.kind, equals(csKind));
    if (isDeprecated) {
      expect(cs.relevance, equals(DART_RELEVANCE_LOW));
    } else {
      expect(cs.relevance, equals(relevance));
    }
    expect(cs.importUri, importUri);
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    if (cs.element != null) {
      expect(cs.element.location, isNotNull);
      expect(cs.element.location.file, isNotNull);
      expect(cs.element.location.offset, isNotNull);
      expect(cs.element.location.length, isNotNull);
      expect(cs.element.location.startColumn, isNotNull);
      expect(cs.element.location.startLine, isNotNull);
    }
    if (elemFile != null) {
      expect(cs.element.location.file, elemFile);
    }
    if (elemOffset != null) {
      expect(cs.element.location.offset, elemOffset);
    }
    return cs;
  }

  /**
   * Return a [Future] that completes with the containing library information
   * after it is accessible via [context.getLibrariesContaining].
   */
  Future computeLibrariesContaining([int times = 200]) {
    List<Source> libraries = context.getLibrariesContaining(testSource);
    if (libraries.isNotEmpty) {
      return new Future.value(libraries);
    }
    context.performAnalysisTask();
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return new Future.delayed(
        Duration.ZERO, () => computeLibrariesContaining(times - 1));
  }

  Future computeSuggestions([int times = 200]) async {
    CompletionRequestImpl baseRequest = new CompletionRequestImpl(
        context, provider, searchEngine, testSource, completionOffset);
    request = new DartCompletionRequestImpl.forRequest(baseRequest);
    var range = new ReplacementRange.compute(request.offset, request.target);
    replacementOffset = range.offset;
    replacementLength = range.length;
    Completer<List<CompletionSuggestion>> completer =
        new Completer<List<CompletionSuggestion>>();

    // Request completions
    contributor
        .computeSuggestions(request)
        .then((List<CompletionSuggestion> computedSuggestions) {
      completer.complete(computedSuggestions);
    });

    // Perform analysis until the suggestions have been computed
    // or the max analysis cycles ([times]) has been reached
    suggestions = await performAnalysis(times, completer);
    expect(suggestions, isNotNull, reason: 'expected suggestions');
  }

  DartCompletionContributor createContributor();

  void failedCompletion(String message,
      [Iterable<CompletionSuggestion> completions]) {
    StringBuffer sb = new StringBuffer(message);
    if (completions != null) {
      sb.write('\n  found');
      completions.toList()
        ..sort(suggestionComparator)
        ..forEach((CompletionSuggestion suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
    }
    fail(sb.toString());
  }

  CompletionSuggestion getSuggest(
      {String completion: null,
      CompletionSuggestionKind csKind: null,
      protocol.ElementKind elemKind: null}) {
    CompletionSuggestion cs;
    if (suggestions != null) {
      suggestions.forEach((CompletionSuggestion s) {
        if (completion != null && completion != s.completion) {
          return;
        }
        if (csKind != null && csKind != s.kind) {
          return;
        }
        if (elemKind != null) {
          protocol.Element element = s.element;
          if (element == null || elemKind != element.kind) {
            return;
          }
        }
        if (cs == null) {
          cs = s;
        } else {
          failedCompletion('expected exactly one $cs',
              suggestions.where((s) => s.completion == completion));
        }
      });
    }
    return cs;
  }

  Future performAnalysis(int times, Completer completer) {
    if (completer.isCompleted) return completer.future;
    if (times == 0 || context == null) return new Future.value();
    context.performAnalysisTask();
    // We use a delayed future to allow microtask events to finish. The
    // Future.value or Future() constructors use scheduleMicrotask themselves and
    // would therefore not wait for microtask callbacks that are scheduled after
    // invoking this method.
    return new Future.delayed(
        Duration.ZERO, () => performAnalysis(times - 1, completer));
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    contributor = createContributor();
  }
}
