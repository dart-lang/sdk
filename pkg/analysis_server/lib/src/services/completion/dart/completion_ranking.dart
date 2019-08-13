// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_ranking_internal.dart';
import 'package:analysis_server/src/services/completion/dart/language_model.dart';
import 'package:analyzer/dart/analysis/features.dart';

/// Number of lookback tokens.
const int _LOOKBACK = 100;

/// Minimum probability to prioritize model-only suggestion.
const double _MODEL_RELEVANCE_CUTOFF = 0.5;

/// Prediction service run by the model isolate.
void entrypoint(SendPort sendPort) {
  LanguageModel model;
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((message) {
    Map<String, Map<String, double>> response = {};
    switch (message['method']) {
      case 'load':
        model = LanguageModel.load(message['args'][0]);
        break;
      case 'predict':
        response['data'] = model.predictWithScores(message['args']);
        break;
    }

    message['port'].send(response);
  });
}

class CompletionRanking {
  /// Singleton instance.
  static CompletionRanking instance;

  /// Filesystem location of model files.
  final String _directory;

  /// Port to communicate from main to model isolate.
  SendPort _write;

  CompletionRanking(this._directory);

  /// Send an RPC to the isolate worker and wait for it to respond.
  Future<Map<String, Map<String, double>>> makeRequest(
      String method, List<String> args) async {
    final port = ReceivePort();
    _write.send({
      'method': method,
      'args': args,
      'port': port.sendPort,
    });
    return await port.first;
  }

  /// Makes a next-token prediction starting at the completion request
  /// cursor and walking back to find previous input tokens.
  Future<Map<String, double>> predict(DartCompletionRequest request) async {
    final query = constructQuery(request, _LOOKBACK);
    if (query == null) {
      return Future.value(null);
    }

    final response = await makeRequest('predict', query);
    return response['data'];
  }

  /// Transforms [CompletionSuggestion] relevances and
  /// [IncludedSuggestionRelevanceTag] relevanceBoosts based on language model
  /// predicted next-token probability distribution.
  Future<List<CompletionSuggestion>> rerank(
      Future<Map<String, double>> probabilityFuture,
      List<CompletionSuggestion> suggestions,
      List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags,
      DartCompletionRequest request,
      FeatureSet featureSet) async {
    final probability = await probabilityFuture
        .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
    if (probability == null || probability.isEmpty) {
      // Failed to compute probability distribution, don't rerank.
      return suggestions;
    }

    // Discard the type-based relevance boosts.
    if (includedSuggestionRelevanceTags != null) {
      includedSuggestionRelevanceTags.forEach((tag) {
        tag.relevanceBoost = 0;
      });
    }

    // Intersection between static analysis and model suggestions.
    var middle = DART_RELEVANCE_HIGH + probability.length;
    // Up to one suggestion from model with very high confidence.
    var high = middle + probability.length;
    // Lower relevance, model-only suggestions (perhaps literals).
    var low = DART_RELEVANCE_LOW - 1;

    List<MapEntry> entries = probability.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (testInsideQuotes(request)) {
      // If completion is requested inside of quotes, remove any suggestions
      // which are not string literal.
      entries = selectStringLiterals(entries);
    } else if (request.opType.includeVarNameSuggestions &&
        suggestions.every((CompletionSuggestion suggestion) =>
            suggestion.kind == CompletionSuggestionKind.IDENTIFIER)) {
      // If analysis server thinks this is a declaration context,
      // remove all of the model-suggested literals.
      // TODO(lambdabaa): Ask Brian for help leveraging
      //     SimpleIdentifier#inDeclarationContext.
      entries.retainWhere((MapEntry entry) => !isLiteral(entry.key));
    }

    var isRequestFollowingDot = testFollowingDot(request);
    entries.forEach((MapEntry entry) {
      // There may be multiple like
      // CompletionSuggestion and CompletionSuggestion().
      final completionSuggestions = suggestions.where((suggestion) =>
          areCompletionsEquivalent(suggestion.completion, entry.key));
      List<IncludedSuggestionRelevanceTag> includedSuggestions;
      if (includedSuggestionRelevanceTags != null) {
        includedSuggestions = includedSuggestionRelevanceTags
            .where((tag) => areCompletionsEquivalent(
                elementNameFromRelevanceTag(tag.tag), entry.key))
            .toList();
      } else {
        includedSuggestions = [];
      }
      if (!isRequestFollowingDot && entry.value > _MODEL_RELEVANCE_CUTOFF) {
        final relevance = high--;
        if (completionSuggestions.isNotEmpty ||
            includedSuggestions.isNotEmpty) {
          completionSuggestions.forEach((completionSuggestion) {
            completionSuggestion.relevance = relevance;
          });
          includedSuggestions.forEach((includedSuggestion) {
            includedSuggestion.relevanceBoost = relevance;
          });
        } else {
          suggestions
              .add(createCompletionSuggestion(entry.key, featureSet, high--));
          if (includedSuggestionRelevanceTags != null) {
            includedSuggestionRelevanceTags
                .add(IncludedSuggestionRelevanceTag(entry.key, relevance));
          }
        }
      } else if (completionSuggestions.isNotEmpty ||
          includedSuggestions.isNotEmpty) {
        final relevance = middle--;
        completionSuggestions.forEach((completionSuggestion) {
          completionSuggestion.relevance = relevance;
        });
        includedSuggestions.forEach((includedSuggestion) {
          includedSuggestion.relevanceBoost = relevance;
        });
      } else if (!isRequestFollowingDot) {
        final relevance = low--;
        suggestions
            .add(createCompletionSuggestion(entry.key, featureSet, relevance));
        if (includedSuggestionRelevanceTags != null) {
          includedSuggestionRelevanceTags
              .add(IncludedSuggestionRelevanceTag(entry.key, relevance));
        }
      }
    });

    return suggestions;
  }

  /// Spins up the model isolate and tells it to load the tflite model.
  Future<void> start() async {
    final port = ReceivePort();
    await Isolate.spawn(entrypoint, port.sendPort);
    this._write = await port.first;
    await makeRequest('load', [_directory]);
  }
}
