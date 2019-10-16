// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_ranking_internal.dart';
import 'package:analysis_server/src/services/completion/dart/language_model.dart';
import 'package:analyzer/dart/analysis/features.dart';

/// Number of lookback tokens.
const int _LOOKBACK = 50;

/// Minimum probability to prioritize model-only suggestion.
const double _MODEL_RELEVANCE_CUTOFF = 0.5;

// TODO(devoncarew): We need to explore the memory costs of running multiple ML
// isolates.
/// Number of code completion isolates.
const int _ISOLATE_COUNT = 4;

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

  /// Ports to communicate from main to model isolates.
  List<SendPort> _writes;

  /// Pointer for round robin load balancing over isolates.
  int _index;

  /// General performance metrics around ML completion.
  final PerformanceMetrics performanceMetrics = PerformanceMetrics._();

  CompletionRanking(this._directory);

  /// Send an RPC to the isolate worker and wait for it to respond.
  Future<Map<String, Map<String, double>>> makeRequest(
      String method, List<String> args) async {
    final port = ReceivePort();
    _writes[_index].send({
      'method': method,
      'args': args,
      'port': port.sendPort,
    });
    this._index = (_index + 1) % _ISOLATE_COUNT;
    return await port.first;
  }

  /// Makes a next-token prediction starting at the completion request cursor
  /// and walking back to find previous input tokens.
  Future<Map<String, double>> predict(DartCompletionRequest request) async {
    final query = constructQuery(request, _LOOKBACK);
    if (query == null) {
      return Future.value();
    }

    request.checkAborted();

    performanceMetrics._incrementPredictionRequestCount();

    final Stopwatch timer = Stopwatch()..start();
    final response = await makeRequest('predict', query);
    timer.stop();

    final Map<String, double> result = response['data'];

    performanceMetrics._addPredictionResult(PredictionResult(
      result,
      timer.elapsed,
      request.source.fullName,
      computeCompletionSnippet(request.sourceContents, request.offset),
    ));

    return result;
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
        .timeout(const Duration(seconds: 1), onTimeout: () => null);
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

    var allowModelOnlySuggestions =
        !testNamedArgument(suggestions) && !testFollowingDot(request);
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
      if (allowModelOnlySuggestions && entry.value > _MODEL_RELEVANCE_CUTOFF) {
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
      } else if (allowModelOnlySuggestions) {
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

  /// Spin up the model isolates and load the tflite model.
  Future<void> start() async {
    this._writes = [];
    this._index = 0;
    final initializations = <Future<void>>[];

    // Start the first isolate.
    await _startIsolate();

    // Start the 2nd and later isolates.
    for (int i = 1; i < _ISOLATE_COUNT; i++) {
      initializations.add(_startIsolate());
    }

    return Future.wait(initializations);
  }

  Future<void> _startIsolate() async {
    final Stopwatch timer = Stopwatch()..start();
    final port = ReceivePort();
    await Isolate.spawn(entrypoint, port.sendPort);
    this._writes.add(await port.first);
    return makeRequest('load', [_directory]).whenComplete(() {
      timer.stop();
      performanceMetrics._isolateInitTimes.add(timer.elapsed);
    });
  }
}

class PerformanceMetrics {
  static const int _maxResultBuffer = 50;

  final Queue<PredictionResult> _predictionResults = Queue();
  int _predictionRequestCount = 0;
  final List<Duration> _isolateInitTimes = [];

  PerformanceMetrics._();

  List<Duration> get isolateInitTimes => _isolateInitTimes;

  /// An iterable of the last `n` prediction results;
  Iterable<PredictionResult> get predictionResults => _predictionResults;

  /// The total prediction requests to ML Complete.
  int get predictionRequestCount => _predictionRequestCount;

  void _addPredictionResult(PredictionResult request) {
    _predictionResults.addFirst(request);
    if (_predictionResults.length > _maxResultBuffer) {
      _predictionResults.removeLast();
    }
  }

  void _incrementPredictionRequestCount() {
    _predictionRequestCount++;
  }
}

class PredictionResult {
  final Map<String, double> results;
  final Duration elapsedTime;
  final String sourcePath;
  final String snippet;

  PredictionResult(
      this.results, this.elapsedTime, this.sourcePath, this.snippet);
}
