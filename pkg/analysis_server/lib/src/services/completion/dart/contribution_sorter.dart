// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.sorter;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';

/**
 * The abstract class [DartContributionSorter] defines the behavior of objects
 * that are used to adjust the relevance of an existing list of suggestions.
 * This is a long-lived object that should not maintain state between
 * calls to it's [sort] method.
 */
abstract class DartContributionSorter {
  /**
   * After [CompletionSuggestion]s have been computed,
   * this method is called to adjust the relevance of those suggestions.
   * Return a [Future] that completes when the suggestions have been updated.
   */
  Future sort(DartCompletionRequest request,
      Iterable<CompletionSuggestion> suggestions);
}
