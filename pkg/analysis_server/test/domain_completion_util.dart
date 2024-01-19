// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'analysis_server_base.dart';

class AbstractCompletionDomainTest extends PubPackageAnalysisServerTest {
  // TODO(brianwilkerson): Merge this class and `CompletionTestCase`.
  late int completionOffset; // TODO(scheglov): remove it
  int? replacementOffset;
  late int replacementLength;
  List<CompletionSuggestion> suggestions = [];

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      {bool isDeprecated = false,
      bool isPotential = false,
      int? selectionOffset,
      int? replacementOffset,
      int? replacementLength,
      ElementKind? elementKind}) {
    CompletionSuggestion? cs;
    for (var s in suggestions) {
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
    }
    if (cs == null) {
      var completions = suggestions.map((s) => s.completion).toList();

      var expectationText = '"$completion"';
      if (elementKind != null) {
        expectationText += ' ($elementKind)';
      }

      fail('expected $expectationText, but found\n $completions');
    }
    var suggestion = cs;
    expect(suggestion.kind, equals(kind));
    expect(suggestion.selectionOffset, selectionOffset ?? completion.length);
    expect(suggestion.selectionLength, equals(0));
    expect(suggestion.replacementOffset, equals(replacementOffset));
    expect(suggestion.replacementLength, equals(replacementLength));
    expect(suggestion.isDeprecated, equals(isDeprecated));
    expect(suggestion.isPotential, equals(isPotential));
  }

  void assertNoResult(String completion, {ElementKind? elementKind}) {
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

  Future<void> getCodeSuggestions({
    required String path,
    required String content,
    int maxResults = 1 << 10,
  }) async {
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    newFile(
      path,
      content.substring(0, completionOffset) +
          content.substring(completionOffset + 1),
    );

    return await getSuggestions(
      path: path,
      completionOffset: completionOffset,
      maxResults: maxResults,
    );
  }

  Future<void> getSuggestions({
    required String path,
    required int completionOffset,
    required int maxResults,
  }) async {
    var request = CompletionGetSuggestions2Params(
      path,
      completionOffset,
      maxResults,
    ).toRequest('0');

    var response = await handleSuccessfulRequest(request);
    var result = CompletionGetSuggestions2Result.fromResponse(response);
    replacementOffset = result.replacementOffset;
    replacementLength = result.replacementLength;
    suggestions = result.suggestions;
  }

  Future<void> getTestCodeSuggestions(String content) {
    return getCodeSuggestions(
      path: testFile.path,
      content: content,
    );
  }

  @override
  Future<void> processNotification(Notification notification) async {
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      fail('server error: ${notification.toJson()}');
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }
}
