// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'analysis_abstract.dart';
import 'constants.dart';

class AbstractCompletionDomainTest extends AbstractAnalysisTest {
  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  Map<String, Completer<void>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  @override
  String addTestFile(String content, {int offset}) {
    completionOffset = content.indexOf('^');
    if (offset != null) {
      expect(completionOffset, -1, reason: 'cannot supply offset and ^');
      completionOffset = offset;
      return super.addTestFile(content);
    }
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    return super.addTestFile(content.substring(0, completionOffset) +
        content.substring(completionOffset + 1));
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      {bool isDeprecated = false,
      bool isPotential = false,
      int selectionOffset,
      ElementKind elementKind}) {
    CompletionSuggestion cs;
    suggestions.forEach((s) {
      if (elementKind != null && s.element?.kind != elementKind) {
        return;
      }
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

      var expectationText = '"$completion"';
      if (elementKind != null) {
        expectationText += ' ($elementKind)';
      }

      fail('expected $expectationText, but found\n $completions');
    }
    expect(cs.kind, equals(kind));
    expect(cs.selectionOffset, selectionOffset ?? completion.length);
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
  }

  void assertNoResult(String completion, {ElementKind elementKind}) {
    if (suggestions.any((cs) =>
        cs.completion == completion &&
        (elementKind == null || cs.element?.kind == elementKind))) {
      fail('did not expect completion: $completion');
    }
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  Future getSuggestions() async {
    await waitForTasksFinished();

    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var response = await waitResponse(request);
    var result = CompletionGetSuggestionsResult.fromResponse(response);
    completionId = result.id;
    assertValidId(completionId);
    await _getResultsCompleter(completionId).future;
    expect(suggestionsDone, isTrue);
  }

  @override
  Future<void> processNotification(Notification notification) async {
    if (notification.event == COMPLETION_RESULTS) {
      var params = CompletionResultsParams.fromNotification(notification);
      var id = params.id;
      assertValidId(id);
      replacementOffset = params.replacementOffset;
      replacementLength = params.replacementLength;
      suggestionsDone = params.isLast;
      expect(suggestionsDone, isNotNull);
      suggestions = params.results;
      expect(allSuggestions.containsKey(id), isFalse);
      allSuggestions[id] = params.results;
      _getResultsCompleter(id).complete(null);
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      fail('server error: ${notification.toJson()}');
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = CompletionDomainHandler(server);
  }

  Completer<void> _getResultsCompleter(String id) {
    return receivedSuggestionsCompleters.putIfAbsent(
        id, () => Completer<void>());
  }
}
