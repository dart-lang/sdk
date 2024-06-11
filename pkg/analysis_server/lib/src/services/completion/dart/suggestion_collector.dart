// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';

/// An object that collects the candidate suggestions produced by the steps.
class SuggestionCollector {
  /// The maximum number of suggestions that will be returned.
  final int maxSuggestions;

  /// The list of candidate suggestions that have been collected.
  final List<CandidateSuggestion> suggestions = [];

  /// A textual representation of the location at which completion was
  /// requested, used to compute the relevance of the suggestions.
  String? completionLocation;

  /// Whether the list of candidate suggestions is potentially incomplete.
  ///
  /// This should be set to `true` anytime a completion pass fails to generate
  /// suggestions, whether because the budget has been exceeded or because of an
  /// exception being thrown.
  bool isIncomplete = false;

  /// Whether the context prefers a constant expression. This is used to compute
  /// relevance.
  bool preferConstants = false;

  /// Initializes a newly created collector to collect candidate suggestions.
  ///
  /// The [maxSuggestions] is the maximum number of suggestions that will be
  /// returned to the client, or `-1` if all of the suggestions should be
  /// returned. This is used to truncate the list of suggestions early, which
  /// - reduces the amount of memory used during completion
  /// - reduces the number of suggestions that need to have relevance scores and
  ///   that need to be converted to the form used by the protocol
  SuggestionCollector({required this.maxSuggestions});

  /// Adds the candidate [suggestion] to the list of suggestions.
  void addSuggestion(CandidateSuggestion suggestion) {
    // Insert the suggestion into the list in sorted order.
    if (suggestions.isEmpty) {
      suggestions.add(suggestion);
      return;
    }
    var score = suggestion.matcherScore;
    var added = false;
    for (var i = suggestions.length - 1; i >= 0; i--) {
      var currentSuggestion = suggestions[i];
      if (currentSuggestion.matcherScore >= score) {
        suggestions.insert(i + 1, suggestion);
        added = true;
        break;
      }
    }
    if (!added) {
      suggestions.insert(0, suggestion);
    }
    // If there are suggestions whose matcher score is too low, remove them.
    //
    // Note that this will allow the list of suggestions to be longer than the
    // maximum number of suggestions as long as at least one suggestion with the
    // lowest score would be kept. Suggestions with the same score will later be
    // sorted by the relevance score and then the lowest bucket will be
    // truncated.
    if (maxSuggestions >= 0 && suggestions.length > maxSuggestions) {
      var minScoreToKeep = suggestions[maxSuggestions].matcherScore;
      while (suggestions.length > maxSuggestions) {
        if (suggestions.last.matcherScore < minScoreToKeep) {
          suggestions.removeLast();
        } else {
          break;
        }
      }
    }
  }
}
