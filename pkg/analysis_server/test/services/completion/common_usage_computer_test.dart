// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.computer.dart.relevance;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart'
    show ContextSourcePair;
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/common_usage_computer.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../analysis_abstract.dart';
import '../../mocks.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(CommonUsageComputerTest);
}

@reflectiveTest
class CommonUsageComputerTest extends AbstractAnalysisTest {
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
    return super.addTestFile(content.substring(0, completionOffset) +
        content.substring(completionOffset + 1));
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      [int relevance = DART_RELEVANCE_DEFAULT, bool isDeprecated = false,
      bool isPotential = false]) {
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

  Future getSuggestions(Map<String, List<String>> selectorRelevance) async {
    await waitForTasksFinished();
    CompletionGetSuggestionsParams params =
        new CompletionGetSuggestionsParams(testFile, completionOffset);
    Request request = params.toRequest('0');
    CompletionDomainHandler domainHandler = new CompletionDomainHandler(server);
    handler = domainHandler;

    ContextSourcePair contextSource = server.getContextSourcePair(params.file);
    AnalysisContext context = contextSource.context;
    Source source = contextSource.source;
    DartCompletionManager completionManager = new DartCompletionManager(context,
        server.searchEngine, source, new DartCompletionCache(context, source),
        null, new CommonUsageComputer(selectorRelevance));

    Response response =
        domainHandler.processRequest(request, completionManager);
    expect(response, isResponseSuccess('0'));
    completionId = response.id;
    assertValidId(completionId);
    await pumpEventQueue();
    expect(suggestionsDone, isTrue);
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
  }

  test_ConstructorName() async {
    // SimpleIdentifier  ConstructorName  InstanceCreationExpression
    addTestFile('import "dart:async"; class A {x() {new Future.^}}');
    await getSuggestions({'dart.async.Future': ['value', 'wait']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'delayed');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'value',
        DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_field() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {static int s1; static int s2; x() {A.^}}');
    await getSuggestions({'.A': ['s2']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's1');
    assertHasResult(
        CompletionSuggestionKind.INVOCATION, 's2', DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_getter() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {int get g1 => 1; int get g2 => 2; x() {new A().^}}');
    await getSuggestions({'.A': ['g2']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'g1');
    assertHasResult(
        CompletionSuggestionKind.INVOCATION, 'g2', DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_setter() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {set s1(v) {}; set s2(v) {}; x() {new A().^}}');
    await getSuggestions({'.A': ['s2']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's1');
    assertHasResult(
        CompletionSuggestionKind.INVOCATION, 's2', DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_static_method() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('import "dart:async"; class A {x() {Future.^}}');
    await getSuggestions({'dart.async.Future': ['value', 'wait']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'wait',
        DART_RELEVANCE_COMMON_USAGE - 1);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PropertyAccess() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestFile('import "dart:math"; class A {x() {new Random().^}}');
    await getSuggestions({'dart.math.Random': ['nextInt', 'nextDouble']});
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextBool');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextDouble',
        DART_RELEVANCE_COMMON_USAGE - 1);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextInt',
        DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Random');
    assertNoResult('Object');
    assertNoResult('A');
  }
}
