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

CompletionSuggestion _createCompletionSuggestionFromAvailableSuggestion(
    AvailableSuggestion suggestion) {
  // todo (pq): IMPLEMENT
  // com.jetbrains.lang.dart.ide.completion.DartServerCompletionContributor#createCompletionSuggestionFromAvailableSuggestion
  return CompletionSuggestion(
      // todo (pq): in IDEA, this is "UNKNOWN" but here we need a value; figure out what's up.
      CompletionSuggestionKind.INVOCATION,
      0,
      suggestion.label,
      0,
      0,
      suggestion.element.isDeprecated,
      false);
}

class CompletionDriver extends AbstractClient with ExpectMixin {
  final bool supportsAvailableSuggestions;
  final MemoryResourceProvider _resourceProvider;

  Map<String, Completer<void>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  final Map<int, AvailableSuggestionSet> idToSetMap = {};
  final Map<String, AvailableSuggestionSet> uriToSetMap = {};
  final Map<String, CompletionResultsParams> idToSuggestions = {};
  final Map<String, ExistingImports> fileToExistingImports = {};

  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;

  CompletionDriver({
    @required this.supportsAvailableSuggestions,
    @required MemoryResourceProvider resourceProvider,
    @required String projectPath,
    @required String testFilePath,
  })  : _resourceProvider = resourceProvider,
        super(
            projectPath: projectPath,
            testFilePath: testFilePath,
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

  @override
  void createProject({Map<String, String> packageRoots}) {
    super.createProject(packageRoots: packageRoots);
    if (supportsAvailableSuggestions) {
      var request = CompletionSetSubscriptionsParams(
          [CompletionService.AVAILABLE_SUGGESTION_SETS]).toRequest('0');
      handleSuccessfulRequest(request, handler: completionHandler);
    }
  }

  Future<List<CompletionSuggestion>> getSuggestions() async {
    await waitForTasksFinished();

    var request = CompletionGetSuggestionsParams(testFilePath, completionOffset)
        .toRequest('0');
    var response = await waitResponse(request);
    var result = CompletionGetSuggestionsResult.fromResponse(response);
    completionId = result.id;
    assertValidId(completionId);
    await _getResultsCompleter(completionId).future;
    expect(suggestionsDone, isTrue);

    if (supportsAvailableSuggestions) {
      // todo(pq): limit set(s)
      for (var suggestionSet in idToSetMap.values) {
        for (var suggestion in suggestionSet.items) {
          var completionSuggestion =
              _createCompletionSuggestionFromAvailableSuggestion(suggestion
                  //, includedSet.getRelevance(), includedRelevanceTags
                  );
          suggestions.add(completionSuggestion);
        }
      }
    }

    return suggestions;
  }

  @override
  File newFile(String path, String content, [int stamp]) =>
      resourceProvider.newFile(path, content, stamp);

  @override
  Folder newFolder(String path) => resourceProvider.newFolder(path);

  @override
  @mustCallSuper
  Future<void> processNotification(Notification notification) async {
    if (notification.event == COMPLETION_RESULTS) {
      var params = CompletionResultsParams.fromNotification(notification);
      var id = params.id;
      assertValidId(id);
      idToSuggestions[id] = params;
      replacementOffset = params.replacementOffset;
      replacementLength = params.replacementLength;
      suggestionsDone = params.isLast;
      expect(suggestionsDone, isNotNull);
      suggestions = params.results;
      expect(allSuggestions.containsKey(id), isFalse);
      allSuggestions[id] = params.results;
      _getResultsCompleter(id).complete(null);
    } else if (notification.event ==
        COMPLETION_NOTIFICATION_AVAILABLE_SUGGESTIONS) {
      var params = CompletionAvailableSuggestionsParams.fromNotification(
        notification,
      );
      for (var set in params.changedLibraries) {
        idToSetMap[set.id] = set;
        uriToSetMap[set.uri] = set;
      }
      for (var id in params.removedLibraries) {
        var set = idToSetMap.remove(id);
        uriToSetMap.remove(set?.uri);
      }
    } else if (notification.event == COMPLETION_NOTIFICATION_EXISTING_IMPORTS) {
      var params = CompletionExistingImportsParams.fromNotification(
        notification,
      );
      fileToExistingImports[params.file] = params.imports;
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      throw Exception('server error: ${notification.toJson()}');
    }
  }

  Future<AvailableSuggestionSet> waitForSetWithUri(String uri) async {
    while (true) {
      var result = uriToSetMap[uri];
      if (result != null) {
        return result;
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Completer<void> _getResultsCompleter(String id) =>
      receivedSuggestionsCompleters.putIfAbsent(id, () => Completer<void>());
}
