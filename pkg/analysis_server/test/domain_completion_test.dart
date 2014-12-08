// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.completion;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/index/index.dart' show Index;
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'mock_sdk.dart';
import 'mocks.dart';
import 'reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionManagerTest);
  runReflectiveTests(CompletionTest);
}

@ReflectiveTestCase()
class CompletionManagerTest extends AbstractAnalysisTest {
  AnalysisDomainHandler analysisDomain;
  Test_CompletionDomainHandler completionDomain;
  Request request;
  int requestCount = 0;
  String testFile2 = '/project/bin/test2.dart';

  AnalysisServer createAnalysisServer(Index index) {
    return new Test_AnalysisServer(
        super.serverChannel,
        super.resourceProvider,
        super.packageMapProvider,
        index,
        new AnalysisServerOptions(),
        new MockSdk());
  }

  void sendRequest(String path) {
    String id = (++requestCount).toString();
    request = new CompletionGetSuggestionsParams(path, 0).toRequest(id);
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess(id));
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    analysisDomain = handler;
    completionDomain = new Test_CompletionDomainHandler(server);
    handler = completionDomain;
    addTestFile('^library A; cl');
    addFile(testFile2, 'library B; cl');
  }

  void tearDown() {
    super.tearDown();
    analysisDomain = null;
    completionDomain = null;
  }

  /**
   * Assert different managers are used for different sources
   */
  test_2_requests_different_sources() {
    expect(completionDomain.manager, isNull);
    sendRequest(testFile);
    expect(completionDomain.manager, isNotNull);
    CompletionManager expectedManager = completionDomain.manager;
    expect(completionDomain.mockContext.mockStream.listenCount, 1);
    expect(completionDomain.mockContext.mockStream.cancelCount, 0);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, expectedManager);
      expect(completionDomain.mockManager.computeCallCount, 1);
      sendRequest(testFile2);
      expect(completionDomain.manager, isNotNull);
      expect(completionDomain.manager, isNot(expectedManager));
      expectedManager = completionDomain.manager;
      expect(completionDomain.mockContext.mockStream.listenCount, 2);
      expect(completionDomain.mockContext.mockStream.cancelCount, 1);
      return pumpEventQueue();
    }).then((_) {
      expect(completionDomain.manager, expectedManager);
      expect(completionDomain.mockContext.mockStream.listenCount, 2);
      expect(completionDomain.mockContext.mockStream.cancelCount, 1);
      expect(completionDomain.mockManager.computeCallCount, 1);
    });
  }

  /**
   * Assert same manager is used for multiple requests on same source
   */
  test_2_requests_same_source() {
    expect(completionDomain.manager, isNull);
    sendRequest(testFile);
    expect(completionDomain.manager, isNotNull);
    expect(completionDomain.manager.source, isNotNull);
    CompletionManager expectedManager = completionDomain.manager;
    expect(completionDomain.mockContext.mockStream.listenCount, 1);
    expect(completionDomain.mockContext.mockStream.cancelCount, 0);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, expectedManager);
      expect(completionDomain.mockManager.computeCallCount, 1);
      sendRequest(testFile);
      expect(completionDomain.manager, expectedManager);
      expect(completionDomain.mockContext.mockStream.listenCount, 1);
      expect(completionDomain.mockContext.mockStream.cancelCount, 0);
      return pumpEventQueue();
    }).then((_) {
      expect(completionDomain.manager, expectedManager);
      expect(completionDomain.mockContext.mockStream.listenCount, 1);
      expect(completionDomain.mockContext.mockStream.cancelCount, 0);
      expect(completionDomain.mockManager.computeCallCount, 2);
    });
  }

  /**
   * Assert manager is NOT cleared when context NOT associated with manager changes.
   */
  test_contextsChanged_different() {
    sendRequest(testFile);
    CompletionManager expectedManager;
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      expectedManager = completionDomain.manager;
      completionDomain.contextsChangedRaw(
          new ContextsChangedEvent(changed: [new MockContext()]));
      return pumpEventQueue();
    }).then((_) {
      expect(completionDomain.manager, expectedManager);
    });
  }

  /**
   * Assert manager is cleared when context associated with manager changes.
   */
  test_contextsChanged_same() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      completionDomain.contextsChangedRaw(
          new ContextsChangedEvent(changed: [completionDomain.mockContext]));
      return pumpEventQueue();
    }).then((_) {
      expect(completionDomain.manager, isNull);
    });
  }

  /**
   * Assert manager is cleared when analysis roots are set
   */
  test_setAnalysisRoots() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      request = new AnalysisSetAnalysisRootsParams([], []).toRequest('7');
      Response response = analysisDomain.handleRequest(request);
      expect(response, isResponseSuccess('7'));
      return pumpEventQueue();
    }).then((_) {
      expect(completionDomain.manager, isNull);
    });
  }

  /**
   * Assert manager is cleared when source NOT associated with manager is changed.
   */
  test_sourcesChanged_different_source_changed() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      ChangeSet changeSet = new ChangeSet();
      changeSet.changedSource(server.getSource(testFile2));
      completionDomain.sourcesChanged(new SourcesChangedEvent(changeSet));
      expect(completionDomain.manager, isNull);
    });
  }

  /**
   * Assert manager is NOT cleared when source associated with manager is changed.
   */
  test_sourcesChanged_same_source_changed() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      CompletionManager expectedManager = completionDomain.manager;
      ChangeSet changeSet = new ChangeSet();
      changeSet.changedSource(completionDomain.manager.source);
      completionDomain.sourcesChanged(new SourcesChangedEvent(changeSet));
      expect(completionDomain.manager, expectedManager);
    });
  }

  /**
   * Assert manager is cleared when source is deleted
   */
  test_sourcesChanged_source_deleted() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      ChangeSet changeSet = new ChangeSet();
      changeSet.deletedSource(completionDomain.manager.source);
      completionDomain.sourcesChanged(new SourcesChangedEvent(changeSet));
      expect(completionDomain.manager, isNull);
    });
  }

  /**
   * Assert manager is cleared when source is removed
   */
  test_sourcesChanged_source_removed() {
    sendRequest(testFile);
    return pumpEventQueue().then((_) {
      expect(completionDomain.manager, isNotNull);
      ChangeSet changeSet = new ChangeSet();
      changeSet.removedSource(completionDomain.manager.source);
      completionDomain.sourcesChanged(new SourcesChangedEvent(changeSet));
      expect(completionDomain.manager, isNull);
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
  final SearchEngine searchEngine;
  CompletionCache cache;
  StreamController<CompletionResult> controller;
  int computeCallCount = 0;

  MockCompletionManager(this.context, this.source, this.searchEngine,
      this.cache);

  @override
  void computeCache() {
    // ignored
  }

  @override
  void computeSuggestions(CompletionRequest request) {
    ++computeCallCount;
    CompletionResult result = new CompletionResult(0, 0, [], true);
    controller.add(result);
  }

  @override
  Stream<CompletionResult> results(CompletionRequest request) {
    controller = new StreamController<CompletionResult>(onListen: () {
      scheduleMicrotask(() {
        computeSuggestions(request);
      });
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

class Test_AnalysisServer extends AnalysisServer {
  final MockContext mockContext = new MockContext();

  Test_AnalysisServer(ServerCommunicationChannel channel,
      ResourceProvider resourceProvider, PackageMapProvider packageMapProvider,
      Index index, AnalysisServerOptions analysisServerOptions, DartSdk defaultSdk)
      : super(
          channel,
          resourceProvider,
          packageMapProvider,
          index,
          analysisServerOptions,
          defaultSdk);

  AnalysisContext getAnalysisContext(String path) {
    return mockContext;
  }
}

/**
 * A [CompletionDomainHandler] subclass that returns a mock completion manager
 * so that the domain handler cache management can be tested.
 */
class Test_CompletionDomainHandler extends CompletionDomainHandler {

  Test_CompletionDomainHandler(Test_AnalysisServer server) : super(server);

  MockContext get mockContext => (server as Test_AnalysisServer).mockContext;

  MockCompletionManager get mockManager => manager;

  void contextsChanged(ContextsChangedEvent event) {
    contextsChangedRaw(
        new ContextsChangedEvent(
            added: event.added.length > 0 ? [mockContext] : [],
            changed: event.changed.length > 0 ? [mockContext] : [],
            removed: event.removed.length > 0 ? [mockContext] : []));
  }

  void contextsChangedRaw(ContextsChangedEvent newEvent) {
    super.contextsChanged(newEvent);
  }

  CompletionManager createCompletionManager(AnalysisContext context,
      Source source, SearchEngine searchEngine, CompletionCache cache) {
    return new MockCompletionManager(mockContext, source, searchEngine, cache);
  }
}
