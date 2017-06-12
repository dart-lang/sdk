// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'analysis_abstract.dart';

class AbstractCompletionDomainTest extends AbstractAnalysisTest {
  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  Map<String, Completer<Null>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  String addTestFile(String content, {int offset}) {
    completionOffset = content.indexOf('^');
    if (offset != null) {
      expect(completionOffset, -1, reason: 'cannot supply offset and ^');
      completionOffset = offset;
      return super.addTestFile(content);
    }
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    return super.addTestFile(content.substring(0, completionOffset) +
        content.substring(completionOffset + 1));
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      {int relevance: DART_RELEVANCE_DEFAULT,
      bool isDeprecated: false,
      bool isPotential: false,
      int selectionOffset}) {
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
    expect(cs.selectionOffset, selectionOffset ?? completion.length);
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
    return createMemoryIndex();
  }

  Future getSuggestions() async {
    await waitForTasksFinished();

    Request request =
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0');
    Response response = await waitResponse(request);
    var result = new CompletionGetSuggestionsResult.fromResponse(response);
    completionId = result.id;
    assertValidId(completionId);
    await _getResultsCompleter(completionId).future;
    expect(suggestionsDone, isTrue);
  }

  processNotification(Notification notification) async {
    if (notification.event == COMPLETION_RESULTS) {
      var params = new CompletionResultsParams.fromNotification(notification);
      String id = params.id;
      assertValidId(id);
      replacementOffset = params.replacementOffset;
      replacementLength = params.replacementLength;
      suggestionsDone = params.isLast;
      expect(suggestionsDone, isNotNull);
      suggestions = params.results;
      expect(allSuggestions.containsKey(id), isFalse);
      allSuggestions[id] = params.results;
      _getResultsCompleter(id).complete(null);
    } else if (notification.event == SERVER_ERROR) {
      fail('server error: ${notification.toJson()}');
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new CompletionDomainHandler(server);
  }

  Completer<Null> _getResultsCompleter(String id) {
    return receivedSuggestionsCompleters.putIfAbsent(
        id, () => new Completer<Null>());
  }
}
