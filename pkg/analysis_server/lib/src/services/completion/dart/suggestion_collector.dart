// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';

/// An object that collects the candidate suggestions produced by the steps.
class SuggestionCollector {
  /// The list of candidate suggestions that have been collected.
  final List<CandidateSuggestion> suggestions = [];

  /// A textual representation of the location at which completion was
  /// requested, used to compute the relevance of the suggestions.
  String? completionLocation;

  /// Initialize a newly created collector to collect candidate suggestions.
  SuggestionCollector();

  /// Add the candidate [suggestion] to the list of suggestions.
  void addSuggestion(CandidateSuggestion suggestion) {
    // TODO(brianwilkerson) This potentially needs to handle shadowed names.
    suggestions.add(suggestion);
  }
}
