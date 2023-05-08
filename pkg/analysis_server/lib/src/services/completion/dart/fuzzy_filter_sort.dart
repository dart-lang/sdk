// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';

final _identifierPattern = RegExp(r'([_a-zA-Z][_a-zA-Z0-9]*)');

/// Filters and scores [suggestions] according to how well they match the
/// [pattern]. Sorts [suggestions] by the score, relevance, and name.
List<CompletionSuggestionBuilder> fuzzyFilterSort({
  required String pattern,
  required List<CompletionSuggestionBuilder> suggestions,
}) {
  final matchStyle =
      suggestions.firstOrNull?.kind == CompletionSuggestionKind.IMPORT
          ? MatchStyle.FILENAME
          : MatchStyle.SYMBOL;
  final matcher = FuzzyMatcher(pattern, matchStyle: matchStyle);

  double score(CompletionSuggestionBuilder suggestion) {
    var textToMatch = suggestion.textToMatch;

    if (suggestion.kind == CompletionSuggestionKind.KEYWORD ||
        suggestion.kind == CompletionSuggestionKind.NAMED_ARGUMENT) {
      var identifier = _identifierPattern.matchAsPrefix(textToMatch)?.group(1);
      if (identifier == null) {
        return -1;
      }
      textToMatch = identifier;
    }

    return matcher.score(textToMatch);
  }

  var scored = suggestions
      .map((e) => _FuzzyScoredSuggestion(e, score(e)))
      .where((e) => e.score > 0)
      .toList();

  scored.sort((a, b) {
    // Prefer what the user requested by typing.
    if (a.score > b.score) {
      return -1;
    } else if (a.score < b.score) {
      return 1;
    }

    // Then prefer what is more relevant in the context.
    if (a.suggestion.relevance != b.suggestion.relevance) {
      return b.suggestion.relevance - a.suggestion.relevance;
    }

    // Other things being equal, sort by name.
    return a.suggestion.completion.compareTo(b.suggestion.completion);
  });

  return scored.map((e) => e.suggestion).toList();
}

/// [CompletionSuggestion] scored using [FuzzyMatcher].
class _FuzzyScoredSuggestion {
  final CompletionSuggestionBuilder suggestion;
  final double score;

  _FuzzyScoredSuggestion(this.suggestion, this.score);
}
