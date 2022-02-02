// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';

import '../../constants.dart';
import '../../domain_completion_test.dart';
import 'expect_mixin.dart';

CompletionSuggestion _createCompletionSuggestionFromAvailableSuggestion(
    AvailableSuggestion suggestion,
    int suggestionSetRelevance,
    Map<String, IncludedSuggestionRelevanceTag>
        includedSuggestionRelevanceTags) {
  // https://github.com/JetBrains/intellij-plugins/blob/59018828753973324ea0500fa4bae93563f1aacf/Dart/src/com/jetbrains/lang/dart/ide/completion/DartServerCompletionContributor.java#L568
  // https://github.com/Dart-Code/Dart-Code/blob/d4e98d2ca2636be5da7334760d73face12414e70/src/extension/providers/dart_completion_item_provider.ts#L187

  var relevanceBoost = 0;
  var relevanceTags = suggestion.relevanceTags;
  if (relevanceTags != null) {
    for (var tag in relevanceTags) {
      var relevanceTag = includedSuggestionRelevanceTags[tag];
      if (relevanceTag != null) {
        relevanceBoost = math.max(relevanceBoost, relevanceTag.relevanceBoost);
      }
    }
  }

  // todo (pq): in IDEA, this is "UNKNOWN" but here we need a value; figure out what's up.
  var suggestionKind = CompletionSuggestionKind.IDENTIFIER;
  if (suggestion.element.kind == ElementKind.CONSTRUCTOR ||
      suggestion.element.kind == ElementKind.FUNCTION ||
      suggestion.element.kind == ElementKind.METHOD) {
    suggestionKind = CompletionSuggestionKind.INVOCATION;
  }

  return CompletionSuggestion(
    suggestionKind,
    suggestionSetRelevance + relevanceBoost,
    suggestion.label,
    0,
    0,
    suggestion.element.isDeprecated,
    false,
    element: suggestion.element,
    returnType: suggestion.element.returnType,
    defaultArgumentListString: suggestion.defaultArgumentListString,
    defaultArgumentListTextRanges: suggestion.defaultArgumentListTextRanges,
    parameterNames: suggestion.parameterNames,
  );
}

class CompletionDriver with ExpectMixin {
  final PubPackageAnalysisServerTest server;
  final bool supportsAvailableSuggestions;

  Map<String, Completer<void>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  final Map<int, AvailableSuggestionSet> idToSetMap = {};
  final Map<String, AvailableSuggestionSet> uriToSetMap = {};
  final Map<String, CompletionResultsParams> idToSuggestions = {};
  final Map<String, ExistingImports> fileToExistingImports = {};

  final Map<String, List<AnalysisError>> filesErrors = {};

  late String completionId;
  late int completionOffset;
  late int replacementOffset;
  late int replacementLength;

  CompletionDriver({
    required this.supportsAvailableSuggestions,
    required this.server,
  }) {
    server.serverChannel.notificationController.stream
        .listen((Notification notification) {
      processNotification(notification);
    });
  }

  void addTestFile(String content, {int? offset}) {
    completionOffset = content.indexOf('^');
    if (offset != null) {
      expect(completionOffset, -1, reason: 'cannot supply offset and ^');
      completionOffset = offset;
      server.newFile(server.testFilePath, content: content);
    } else {
      expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
      var nextOffset = content.indexOf('^', completionOffset + 1);
      expect(nextOffset, equals(-1), reason: 'too many ^');
      server.newFile(server.testFilePath,
          content: content.substring(0, completionOffset) +
              content.substring(completionOffset + 1));
    }
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  Future<void> createProject() async {
    await server.setRoots(included: [server.workspaceRootPath], excluded: []);

    if (supportsAvailableSuggestions) {
      await server.handleRequest(
        CompletionSetSubscriptionsParams([
          CompletionService.AVAILABLE_SUGGESTION_SETS,
        ]).toRequest('0'),
      );
    }
  }

  Future<List<CompletionSuggestion>> getSuggestions() async {
    var request = CompletionGetSuggestionsParams(
      server.convertPath(server.testFilePath),
      completionOffset,
    ).toRequest('0');
    var response = await server.handleRequest(request);
    var result = CompletionGetSuggestionsResult.fromResponse(response);
    completionId = result.id;
    assertValidId(completionId);
    await _getResultsCompleter(completionId).future;
    return suggestions;
  }

  Future<List<CompletionSuggestion>> getSuggestions2() async {
    var request = CompletionGetSuggestions2Params(
      server.convertPath(server.testFilePath),
      completionOffset,
      1 << 16,
      timeout: 60 * 1000,
    ).toRequest('0');
    var response = await server.handleRequest(request);
    var result = CompletionGetSuggestions2Result.fromResponse(response);
    replacementOffset = result.replacementOffset;
    replacementLength = result.replacementLength;
    return result.suggestions;
  }

  @mustCallSuper
  Future<void> processNotification(Notification notification) async {
    if (notification.event == COMPLETION_RESULTS) {
      var params = CompletionResultsParams.fromNotification(notification);
      var id = params.id;
      assertValidId(id);
      idToSuggestions[id] = params;
      replacementOffset = params.replacementOffset;
      replacementLength = params.replacementLength;
      suggestions = params.results;
      expect(allSuggestions.containsKey(id), isFalse);
      allSuggestions[id] = params.results;
      var includedKinds = params.includedElementKinds;

      //
      // Collect relevance information.
      //

      // https://github.com/JetBrains/intellij-plugins/blob/59018828753973324ea0500fa4bae93563f1aacf/Dart/src/com/jetbrains/lang/dart/analyzer/DartAnalysisServerService.java#L467
      var includedRelevanceTags = <String, IncludedSuggestionRelevanceTag>{};
      var includedSuggestionRelevanceTags =
          params.includedSuggestionRelevanceTags;
      if (includedSuggestionRelevanceTags != null) {
        for (var includedRelevanceTag in includedSuggestionRelevanceTags) {
          includedRelevanceTags[includedRelevanceTag.tag] =
              includedRelevanceTag;
        }
      }

      //
      // Identify imported libraries.
      //

      var importedLibraryUris = <String>{};
      var existingImports = fileToExistingImports[params.libraryFile];
      if (existingImports != null) {
        for (var existingImport in existingImports.imports) {
          var uri = existingImports.elements.strings[existingImport.uri];
          importedLibraryUris.add(uri);
        }
      }

      //
      // Partition included suggestion sets into imported and not-imported groups.
      //

      var importedSets = <IncludedSuggestionSet>[];
      var notImportedSets = <IncludedSuggestionSet>[];

      for (var set in params.includedSuggestionSets!) {
        var id = set.id;
        while (!idToSetMap.containsKey(id)) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
        var suggestionSet = idToSetMap[id]!;
        if (importedLibraryUris.contains(suggestionSet.uri)) {
          importedSets.add(set);
        } else {
          notImportedSets.add(set);
        }
      }

      //
      // Add suggestions.
      //
      // First from imported then from not-imported sets.
      //

      void addSuggestion(
          AvailableSuggestion suggestion, IncludedSuggestionSet includeSet) {
        var kind = suggestion.element.kind;
        if (!includedKinds!.contains(kind)) {
          return;
        }
        var completionSuggestion =
            _createCompletionSuggestionFromAvailableSuggestion(
                suggestion, includeSet.relevance, includedRelevanceTags);
        suggestions.add(completionSuggestion);
      }

      // Track seen elements to ensure they are not duplicated.
      var seenElements = <String>{};

      // Suggestions can be uniquely identified by kind, label and uri.
      String suggestionId(AvailableSuggestion s) =>
          '${s.declaringLibraryUri}:${s.element.kind}:${s.label}';

      for (var includeSet in importedSets) {
        var set = idToSetMap[includeSet.id]!;
        for (var suggestion in set.items) {
          if (seenElements.add(suggestionId(suggestion))) {
            addSuggestion(suggestion, includeSet);
          }
        }
      }

      for (var includeSet in notImportedSets) {
        var set = idToSetMap[includeSet.id]!;
        for (var suggestion in set.items) {
          if (!seenElements.contains(suggestionId(suggestion))) {
            addSuggestion(suggestion, includeSet);
          }
        }
      }

      _getResultsCompleter(id).complete(null);
    } else if (notification.event ==
        COMPLETION_NOTIFICATION_AVAILABLE_SUGGESTIONS) {
      var params = CompletionAvailableSuggestionsParams.fromNotification(
        notification,
      );
      for (var set in params.changedLibraries!) {
        idToSetMap[set.id] = set;
        uriToSetMap[set.uri] = set;
      }
      for (var id in params.removedLibraries!) {
        var set = idToSetMap.remove(id);
        uriToSetMap.remove(set?.uri);
      }
    } else if (notification.event == COMPLETION_NOTIFICATION_EXISTING_IMPORTS) {
      var params = CompletionExistingImportsParams.fromNotification(
        notification,
      );
      fileToExistingImports[params.file] = params.imports;
    } else if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      throw Exception('server error: ${notification.toJson()}');
    } else if (notification.event == SERVER_NOTIFICATION_CONNECTED) {
      // Ignored.
    } else {
      print('Unhandled notififcation: ${notification.event}');
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
