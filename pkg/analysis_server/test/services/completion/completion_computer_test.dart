// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.suggestion;

import 'dart:async';

import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/completion_suggestion.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(DartCompletionManagerTest);
}

/**
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

@ReflectiveTestCase()
class DartCompletionManagerTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;
  Source source;
  DartCompletionManager manager;
  MockCompletionComputer computer1;
  MockCompletionComputer computer2;
  CompletionSuggestion suggestion1;
  CompletionSuggestion suggestion2;

  void resolveLibrary() {
    context.resolveCompilationUnit(
        source,
        context.computeLibraryElement(source));
  }

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    source = addSource('/does/not/exist.dart', '');
    manager = new DartCompletionManager(context, searchEngine, source, 17);
    suggestion1 = new CompletionSuggestion(
        CompletionSuggestionKind.CLASS,
        CompletionRelevance.DEFAULT,
        "suggestion1",
        1,
        1,
        false,
        false);
    suggestion2 = new CompletionSuggestion(
        CompletionSuggestionKind.CLASS,
        CompletionRelevance.DEFAULT,
        "suggestion2",
        2,
        2,
        false,
        false);
  }

  test_compute_fastAndFull() {
    computer1 = new MockCompletionComputer(suggestion1, null);
    computer2 = new MockCompletionComputer(null, suggestion2);
    manager.computers = [computer1, computer2];
    int count = 0;
    bool done = false;
    manager.results().listen((CompletionResult r) {
      switch (++count) {
        case 1:
          computer1.assertCalls(context, source, 17, searchEngine);
          computer2.assertCalls(context, source, 17, searchEngine);
          expect(r.last, isFalse);
          expect(r.suggestions, hasLength(1));
          expect(r.suggestions, contains(suggestion1));
          resolveLibrary();
          break;
        case 2:
          computer1.assertFull(0);
          computer2.assertFull(1);
          expect(r.last, isTrue);
          expect(r.suggestions, hasLength(2));
          expect(r.suggestions, contains(suggestion1));
          expect(r.suggestions, contains(suggestion2));
          break;
        default:
          fail('unexpected');
      }
    }, onDone: () {
      done = true;
      expect(count, equals(2));
    });
    return pumpEventQueue().then((_) {
      expect(done, isTrue);
    });
  }

  test_compute_fastOnly() {
    computer1 = new MockCompletionComputer(suggestion1, null);
    computer2 = new MockCompletionComputer(suggestion2, null);
    manager.computers = [computer1, computer2];
    int count = 0;
    bool done = false;
    manager.results().listen((CompletionResult r) {
      switch (++count) {
        case 1:
          computer1.assertCalls(context, source, 17, searchEngine);
          computer2.assertCalls(context, source, 17, searchEngine);
          expect(r.last, isTrue);
          expect(r.suggestions, hasLength(2));
          expect(r.suggestions, contains(suggestion1));
          expect(r.suggestions, contains(suggestion2));
          break;
        default:
          fail('unexpected');
      }
    }, onDone: () {
      done = true;
      expect(count, equals(1));
    });
    return pumpEventQueue().then((_) {
      expect(done, isTrue);
    });
  }
}

class MockCompletionComputer extends DartCompletionComputer {
  final CompletionSuggestion fastSuggestion;
  final CompletionSuggestion fullSuggestion;
  int fastCount = 0;
  int fullCount = 0;
  DartCompletionRequest request;

  MockCompletionComputer(this.fastSuggestion, this.fullSuggestion);

  assertCalls(AnalysisContext context, Source source, int offset,
      SearchEngine searchEngine) {
    expect(request.context, equals(context));
    expect(request.source, equals(source));
    expect(request.offset, equals(offset));
    expect(request.searchEngine, equals(searchEngine));
    expect(this.fastCount, equals(1));
    expect(this.fullCount, equals(0));
  }

  assertFull(int fullCount) {
    expect(this.fastCount, equals(1));
    expect(this.fullCount, equals(fullCount));
  }

  @override
  bool computeFast(DartCompletionRequest request) {
    this.request = request;
    fastCount++;
    if (fastSuggestion != null) {
      request.suggestions.add(fastSuggestion);
    }
    return fastSuggestion != null;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    this.request = request;
    fullCount++;
    if (fullSuggestion != null) {
      request.suggestions.add(fullSuggestion);
    }
    return new Future.value(fullSuggestion != null);
  }
}
