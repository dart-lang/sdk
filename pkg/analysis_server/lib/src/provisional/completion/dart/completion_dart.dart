// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';

export 'package:analyzer_plugin/utilities/completion/relevance.dart';

/// An object that contributes results for the `completion.getSuggestions`
/// request results.
abstract class DartCompletionContributor {
  final DartCompletionRequest request;
  final SuggestionBuilder builder;

  DartCompletionContributor(this.request, this.builder);

  /// Return a [Future] that completes when the suggestions appropriate for the
  /// given completion [request] have been added to the [builder].
  Future<void> computeSuggestions();
}
