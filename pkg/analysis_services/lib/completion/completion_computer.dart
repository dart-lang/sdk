// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer;

import 'dart:async';

import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/src/completion/top_level_computer.dart';
import 'package:analysis_services/search/search_engine.dart';

/**
 * The base class for computing code completion suggestions.
 */
abstract class CompletionComputer {

  /**
   * Create a collection of code completion computers for the given situation.
   */
  static Future<List<CompletionComputer>> create(SearchEngine searchEngine) {
    List<CompletionComputer> computers = [];
    computers.add(new TopLevelComputer(searchEngine));
    return new Future.value(computers);
  }

  /**
   * Computes [CompletionSuggestion]s for the specified position in the source.
   */
  Future<List<CompletionSuggestion>> compute();
}
