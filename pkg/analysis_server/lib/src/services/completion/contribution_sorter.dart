// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.sorter;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/completion_dart.dart';

/**
 * The abstract class `ContributionSorter` defines the behavior of objects
 * that are used to adjust the relevance of an existing list of suggestions.
 * This is a long-lived object that should not maintain state between
 * calls to it's [sort] method.
 */
abstract class ContributionSorter {
  /**
   * After [CompletionSuggestion]s have been computed,
   * this method is called to adjust the relevance of those suggestions.
   * The compilation unit and completion node
   * in the given completion context may not be resolved.
   * This method should execute quickly and not block.
   */
  void sort(DartCompletionRequest request,
      Iterable<CompletionSuggestion> suggestions);
}
