// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.completion;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/index/index.dart' show Index;
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';
import 'reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionCacheTest);
  runReflectiveTests(CompletionTest);
}

@ReflectiveTestCase()
class CompletionCacheTest extends AbstractAnalysisTest {
  AnalysisDomainHandler analysisDomain;

  @override
  void setUp() {
    super.setUp();
    createProject();
    analysisDomain = handler;
    handler = new Test_CompletionDomainHandler(server);
  }

  void tearDown() {
    super.tearDown();
    analysisDomain = null;
  }

  test_cache() {
    Test_CompletionDomainHandler target = handler;
    addTestFile('^library A; cl');
    Request request =
        new CompletionGetSuggestionsParams(testFile, 0).toRequest('0');

    /*
     * Assert cache is created by manager
     * and context.onSourceChanged listen is called
     */
    Source source;
    var expectedCache = null;
    handleSuccessfulRequest(request);
    return pumpEventQueue().then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expect(target.completionManager.computeCallCount, 1);
      source = target.completionManager.source;
      expect(source, isNotNull);
      expectedCache = target.completionManager.cache;
      expect(expectedCache, isNotNull);
      expect(target.mockContext.mockStream.listenCount, 1);
      expect(target.mockContext.mockStream.cancelCount, 0);

      /*
       * Assert cache is stored in target,
       * and context.onSourceChanged listen has not changed
       */
      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 1);
      expect(target.mockContext.mockStream.cancelCount, 0);

      /*
       * Assert same cache and listening is preserved across multiple calls
       */
      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 1);
      expect(target.mockContext.mockStream.cancelCount, 0);

      /*
       * Trigger source change event that should NOT clear existing cache
       */
      target.sourcesChanged(new SourcesChangedEvent.changedContent(source, ''));
    }).then((_) {

      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 1);
      expect(target.mockContext.mockStream.cancelCount, 0);

      /*
       * Trigger source change event that should clear existing cache
       * and assert subscription.cancel is called when the cache is discarded.
       */
      ChangeSet changeSet = new ChangeSet();
      changeSet.removedSource(source);
      target.sourcesChanged(new SourcesChangedEvent(changeSet));
    }).then((_) {
      expect(target.mockContext.mockStream.listenCount, 1);
      expect(target.mockContext.mockStream.cancelCount, 1);

      /*
       * Assert that cache was cleared, recreated,
       * and context.onSourceChanged listen is called again.
       */
      expectedCache = null;
      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expectedCache = target.completionManager.cache;
      expect(expectedCache, isNotNull);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 2);
      expect(target.mockContext.mockStream.cancelCount, 1);

      /*
       * Assert same cache and listening is preserved across multiple calls
       */
      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 2);
      expect(target.mockContext.mockStream.cancelCount, 1);

      /*
       * Trigger context change event that should clear existing cache
       */
      Request request =
          new AnalysisSetAnalysisRootsParams([], []).toRequest('0');
      Response response = analysisDomain.handleRequest(request);
      expect(response, isResponseSuccess('0'));
      return pumpEventQueue();
    }).then((_) {
      expect(target.mockContext.mockStream.listenCount, 2);
      expect(target.mockContext.mockStream.cancelCount, 2);

      /*
       * Assert that cache was cleared, recreated,
       * and context.onSourceChanged listen is called again.
       */
      expectedCache = null;
      handleSuccessfulRequest(request);
      return pumpEventQueue();
    }).then((_) {
      expect(identical(target.cacheReceived, expectedCache), isTrue);
      expectedCache = target.completionManager.cache;
      expect(expectedCache, isNotNull);
      expect(target.completionManager.computeCallCount, 1);
      expect(target.mockContext.mockStream.listenCount, 3);
      expect(target.mockContext.mockStream.cancelCount, 2);
    });
  }
}

@ReflectiveTestCase()
class CompletionTest extends AbstractAnalysisTest {
  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;

  String addTestFile(String content) {
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    return super.addTestFile(
        content.substring(0, completionOffset) +
            content.substring(completionOffset + 1));
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
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

  void assertNoResult(String completion) {
    if (suggestions.any((cs) => cs.completion == completion)) {
      fail('did not expect completion: $completion');
    }
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  Future getSuggestions() {
    return waitForTasksFinished().then((_) {
      Request request =
          new CompletionGetSuggestionsParams(testFile, completionOffset).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      completionId = response.id;
      assertValidId(completionId);
      return pumpEventQueue().then((_) {
        expect(suggestionsDone, isTrue);
      });
    });
  }

  void processNotification(Notification notification) {
    if (notification.event == COMPLETION_RESULTS) {
      var params = new CompletionResultsParams.fromNotification(notification);
      String id = params.id;
      assertValidId(id);
      if (id == completionId) {
        expect(suggestionsDone, isFalse);
        replacementOffset = params.replacementOffset;
        replacementLength = params.replacementLength;
        suggestionsDone = params.isLast;
        expect(suggestionsDone, isNotNull);
        suggestions = params.results;
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new CompletionDomainHandler(server);
  }

  test_html() {
    testFile = '/project/web/test.html';
    addTestFile('''
      <html>^</html>
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      expect(suggestions, hasLength(0));
    });
  }

  test_imports() {
    addTestFile('''
      import 'dart:html';
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement');
      assertNoResult('test');
    });
  }

  test_imports_prefixed() {
    addTestFile('''
      import 'dart:html' as foo;
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  test_invocation() {
    addTestFile('class A {b() {}} main() {A a; a.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  test_keyword() {
    addTestFile('library A; cl^');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 2));
      expect(replacementLength, equals(2));
      assertHasResult(
          CompletionSuggestionKind.KEYWORD,
          'import',
          CompletionRelevance.HIGH);
      assertHasResult(
          CompletionSuggestionKind.KEYWORD,
          'class',
          CompletionRelevance.HIGH);
    });
  }

  test_locals() {
    addTestFile('class A {var a; x() {var b;^}}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'a');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'x');
    });
  }

  test_topLevel() {
    addTestFile('''
      typedef foo();
      var test = '';
      main() {tes^t}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 3));
      expect(replacementLength, equals(4));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'test');
      assertNoResult('HtmlElement');
    });
  }
}

class MockCache extends CompletionCache {
  MockCache(AnalysisContext context, Source source) : super(context, source);
}

class MockCompletionManager implements CompletionManager {
  final AnalysisContext context;
  final Source source;
  final int offset;
  final SearchEngine searchEngine;
  CompletionCache cache;
  CompletionPerformance performance;
  StreamController<CompletionResult> controller;
  int computeCallCount = 0;

  MockCompletionManager(this.context, this.source, this.offset,
      this.searchEngine, this.cache, this.performance);

  @override
  CompletionCache get completionCache {
    if (cache == null) {
      cache = new MockCache(context, source);
    }
    return cache;
  }

  @override
  void compute() {
    ++computeCallCount;
    CompletionResult result = new CompletionResult(0, 0, [], true);
    controller.add(result);
  }

  @override
  Stream<CompletionResult> results() {
    controller = new StreamController<CompletionResult>(onListen: () {
      scheduleMicrotask(compute);
    });
    return controller.stream;
  }
}

/**
 * Mock [AnaysisContext] for tracking usage of onSourcesChanged.
 */
class MockContext implements AnalysisContext {
  MockStream<SourcesChangedEvent> mockStream;

  MockContext() {
    mockStream = new MockStream<SourcesChangedEvent>();
  }

  @override
  Stream<SourcesChangedEvent> get onSourcesChanged => mockStream;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Mock stream for tracking calls to listen and subscription.cancel.
 */
class MockStream<E> implements Stream<E> {
  MockSubscription<E> mockSubscription = new MockSubscription<E>();
  int listenCount = 0;

  int get cancelCount => mockSubscription.cancelCount;

  @override
  StreamSubscription<E> listen(void onData(E event), {Function onError, void
      onDone(), bool cancelOnError}) {
    ++listenCount;
    return mockSubscription;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Mock subscription for tracking calls to subscription.cancel.
 */
class MockSubscription<E> implements StreamSubscription<E> {
  int cancelCount = 0;

  Future cancel() {
    ++cancelCount;
    return new Future.value(true);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A [CompletionDomainHandler] subclass that returns a mock completion manager
 * so that the domain handler cache management can be tested.
 */
class Test_CompletionDomainHandler extends CompletionDomainHandler {
  CompletionCache cacheReceived;
  final MockContext mockContext = new MockContext();
  MockCompletionManager completionManager;

  Test_CompletionDomainHandler(AnalysisServer server) : super(server);

  void contextsChanged(ContextsChangedEvent event) {
    if (event.removed.length == 1) {
      event = new ContextsChangedEvent(
          added: event.added,
          changed: event.changed,
          removed: [mockContext]);
    }
    super.contextsChanged(event);
  }

  CompletionManager createCompletionManager(AnalysisContext context,
      Source source, int offset, SearchEngine searchEngine, CompletionCache cache,
      CompletionPerformance performance) {
    cacheReceived = cache;
    completionManager = new MockCompletionManager(
        mockContext,
        source,
        offset,
        searchEngine,
        cache,
        performance);
    return completionManager;
  }
}
