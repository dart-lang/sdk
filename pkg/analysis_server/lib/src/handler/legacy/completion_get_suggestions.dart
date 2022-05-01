// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestions2.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `completion.getSuggestions` request.
class CompletionGetSuggestionsHandler extends CompletionGetSuggestions2Handler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  CompletionGetSuggestionsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    if (completionIsDisabled) {
      return;
    }

    var requestLatency = request.timeSinceRequest;
    var budget = CompletionBudget(server.completionState.budgetDuration);

    // extract and validate params
    var params = CompletionGetSuggestionsParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var performance = OperationPerformanceImpl('<root>');
    performance.runAsync(
      'request',
      (performance) async {
        if (file.endsWith('.yaml')) {
          // Return the response without results.
          var completionId =
              (server.completionState.nextCompletionId++).toString();
          server.sendResponse(CompletionGetSuggestionsResult(completionId)
              .toResponse(request.id));
          // Send a notification with results.
          final suggestions = computeYamlSuggestions(file, offset);
          sendCompletionNotification(
            completionId,
            suggestions.replacementOffset,
            suggestions.replacementLength,
            suggestions.suggestions,
            null,
            null,
            null,
            null,
          );
          return;
        } else if (!file.endsWith('.dart')) {
          // Return the response without results.
          var completionId =
              (server.completionState.nextCompletionId++).toString();
          server.sendResponse(CompletionGetSuggestionsResult(completionId)
              .toResponse(request.id));
          // Send a notification with results.
          sendCompletionNotification(
              completionId, offset, 0, [], null, null, null, null);
          return;
        }

        var resolvedUnit = await server.getResolvedUnit(file);
        if (resolvedUnit == null) {
          server.sendResponse(Response.fileNotAnalyzed(request, file));
          return;
        }

        server.requestStatistics?.addItemTimeNow(request, 'resolvedUnit');

        if (offset < 0 || offset > resolvedUnit.content.length) {
          server.sendResponse(Response.invalidParameter(
              request,
              'params.offset',
              'Expected offset between 0 and source length inclusive,'
                  ' but found $offset'));
          return;
        }

        final completionPerformance = CompletionPerformance(
          operation: performance,
          path: file,
          requestLatency: requestLatency,
          content: resolvedUnit.content,
          offset: offset,
        );
        server.completionState.performanceList.add(completionPerformance);

        var declarationsTracker = server.declarationsTracker;
        if (declarationsTracker == null) {
          server.sendResponse(Response.unsupportedFeature(
              request.id, 'Completion is not enabled.'));
          return;
        }

        var completionRequest = DartCompletionRequest.forResolvedUnit(
          resolvedUnit: resolvedUnit,
          offset: offset,
          dartdocDirectiveInfo: server.getDartdocDirectiveInfoFor(
            resolvedUnit,
          ),
          documentationCache: server.getDocumentationCacheFor(resolvedUnit),
        );

        var completionId =
            (server.completionState.nextCompletionId++).toString();

        setNewRequest(completionRequest);

        // initial response without results
        server.sendResponse(CompletionGetSuggestionsResult(completionId)
            .toResponse(request.id));

        // If the client opted into using available suggestion sets,
        // create the kinds set, so signal the completion manager about opt-in.
        Set<ElementKind>? includedElementKinds;
        Set<String>? includedElementNames;
        List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;
        if (server.completionState.subscriptions
            .contains(CompletionService.AVAILABLE_SUGGESTION_SETS)) {
          includedElementKinds = <ElementKind>{};
          includedElementNames = <String>{};
          includedSuggestionRelevanceTags = <IncludedSuggestionRelevanceTag>[];
        }

        // Compute suggestions in the background
        try {
          var suggestionBuilders = <CompletionSuggestionBuilder>[];
          try {
            suggestionBuilders = await computeSuggestions(
              budget: budget,
              performance: performance,
              request: completionRequest,
              includedElementKinds: includedElementKinds,
              includedElementNames: includedElementNames,
              includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
            );
          } on AbortCompletion {
            // Continue with empty suggestions list.
          }
          String? libraryFile;
          var includedSuggestionSets = <IncludedSuggestionSet>[];
          if (includedElementKinds != null && includedElementNames != null) {
            libraryFile = resolvedUnit.libraryElement.source.fullName;
            server.sendNotification(
              createExistingImportsNotification(resolvedUnit),
            );
            computeIncludedSetList(
              declarationsTracker,
              completionRequest,
              includedSuggestionSets,
              includedElementNames,
            );
          }

          const SEND_NOTIFICATION_TAG = 'send notification';
          performance.run(SEND_NOTIFICATION_TAG, (_) {
            sendCompletionNotification(
              completionId,
              completionRequest.replacementOffset,
              completionRequest.replacementLength,
              suggestionBuilders.map((e) => e.build()).toList(),
              libraryFile,
              includedSuggestionSets,
              includedElementKinds?.toList(),
              includedSuggestionRelevanceTags,
            );
          });

          completionPerformance.computedSuggestionCount =
              suggestionBuilders.length;
          completionPerformance.transmittedSuggestionCount =
              suggestionBuilders.length;
        } finally {
          _ifMatchesRequestClear(completionRequest);
        }
      },
    );
  }

  void _ifMatchesRequestClear(DartCompletionRequest request) {
    if (server.completionState.currentRequest == request) {
      server.completionState.currentRequest = null;
    }
  }
}
