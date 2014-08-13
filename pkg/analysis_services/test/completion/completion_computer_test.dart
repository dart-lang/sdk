// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.suggestion;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/completion/dart_completion_manager.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_context.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionManagerTest);
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
class CompletionManagerTest extends AbstractContextTest {

  test_dart() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = CompletionManager.create(context, source, 0, null);
    expect(manager.runtimeType, DartCompletionManager);
  }

  test_html() {
    Source source = addSource('/does/not/exist.html', '');
    var manager = CompletionManager.create(context, source, 0, null);
    expect(manager.runtimeType, NoOpCompletionManager);
  }

  test_null_context() {
    Source source = addSource('/does/not/exist.dart', '');
    var manager = CompletionManager.create(null, source, 0, null);
    expect(manager.runtimeType, NoOpCompletionManager);
  }

  test_other() {
    Source source = addSource('/does/not/exist.foo', '');
    var manager = CompletionManager.create(context, source, 0, null);
    expect(manager.runtimeType, NoOpCompletionManager);
  }
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

  @override
  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    source = addSource('/does/not/exist.dart', '');
    manager = new DartCompletionManager(context, source, 17, searchEngine);
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

  void resolveLibrary() {
    context.resolveCompilationUnit(
        source,
        context.computeLibraryElement(source));
  }
}

class MockCompletionComputer extends CompletionComputer {
  final CompletionSuggestion fastSuggestion;
  final CompletionSuggestion fullSuggestion;
  int fastCount = 0;
  int fullCount = 0;

  MockCompletionComputer(this.fastSuggestion, this.fullSuggestion);

  assertCalls(AnalysisContext context, Source source, int offset,
      SearchEngine searchEngine) {
    expect(this.context, equals(context));
    expect(this.source, equals(source));
    expect(this.offset, equals(offset));
    expect(this.searchEngine, equals(searchEngine));
    expect(this.fastCount, equals(1));
    expect(this.fullCount, equals(0));
  }

  assertFull(int fullCount) {
    expect(this.fastCount, equals(1));
    expect(this.fullCount, equals(fullCount));
  }

  @override
  bool computeFast(CompilationUnit unit, AstNode node,
      List<CompletionSuggestion> suggestions) {
    fastCount++;
    if (fastSuggestion != null) {
      suggestions.add(fastSuggestion);
    }
    return fastSuggestion != null;
  }

  @override
  Future<bool> computeFull(CompilationUnit unit, AstNode node,
      List<CompletionSuggestion> suggestions) {
    fullCount++;
    if (fullSuggestion != null) {
      suggestions.add(fullSuggestion);
    }
    return new Future.value(fullSuggestion != null);
  }
}
