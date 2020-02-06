// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';

import '../../constants.dart';
import 'abstract_client.dart';
import 'expect_mixin.dart';

class CompletionDriver extends AbstractClient with ExpectMixin {
  final bool supportsAvailableDeclarations;
  final MemoryResourceProvider _resourceProvider;

  Map<String, Completer<void>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;

  CompletionDriver({
    @required this.supportsAvailableDeclarations,
    @required MemoryResourceProvider resourceProvider,
  })  : _resourceProvider = resourceProvider,
        super(
            projectPath: resourceProvider.convertPath('/project'),
            testFolder: resourceProvider.convertPath('/project/bin'),
            testFile: resourceProvider.convertPath('/project/bin/test.dart'),
            sdkPath: resourceProvider.convertPath('/sdk'));

  @override
  MemoryResourceProvider get resourceProvider => _resourceProvider;

  @override
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

  Future<List<CompletionSuggestion>> getSuggestions() async {
    await waitForTasksFinished();

    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var response = await waitResponse(request);
    var result = CompletionGetSuggestionsResult.fromResponse(response);
    completionId = result.id;
    assertValidId(completionId);
    await _getResultsCompleter(completionId).future;
    expect(suggestionsDone, isTrue);
    return suggestions;
  }

  @override
  File newFile(String path, String content, [int stamp]) =>
      resourceProvider.newFile(path, content, stamp);

  @override
  Folder newFolder(String path) => resourceProvider.newFolder(path);

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
      throw Exception('server error: ${notification.toJson()}');
    }
  }

  Completer<void> _getResultsCompleter(String id) =>
      receivedSuggestionsCompleters.putIfAbsent(id, () => Completer<void>());
}
