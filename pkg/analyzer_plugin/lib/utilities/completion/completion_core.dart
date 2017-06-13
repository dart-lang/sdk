// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * An exception that is thrown when the current completion request should be
 * aborted because either the source changed since the request was made, or
 * a new completion request was received. See [CompletionRequest.checkAborted].
 */
class AbortCompletion {}

/**
 * An object that [CompletionContributor]s use to record completion suggestions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CompletionCollector {
  /**
   * Set the length of the region of text that should be replaced by the
   * selected completion suggestion.
   *
   * The length can only be set once and applies to all of the suggestions.
   * Hence, this setter throws a [StateError] if the length has already been
   * set.
   */
  void set length(int length);

  /**
   * Set the offset of the region of text that should be replaced by the
   * selected completion suggestion.
   *
   * The offset can only be set once and applies to all of the suggestions.
   * Hence, this setter throws a [StateError] if the offset has already been
   * set.
   */
  void set offset(int offset);

  /**
   * Indicates if the collector's offset has been set (and ultimately the
   * length too).
   */
  bool get offsetIsSet;

  /**
   * Returns length of suggestions currently held.
   */
  int get suggestionsLength;

  /**
   * Record the given completion [suggestion].
   */
  void addSuggestion(CompletionSuggestion suggestion);
}

/**
 * An object used to produce completion suggestions.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class CompletionContributor {
  /**
   * Contribute completion suggestions for the completion location specified by
   * the given [request] into the given [collector].
   */
  Future<Null> computeSuggestions(
      CompletionRequest request, CompletionCollector collector);
}

/**
 * A generator that will generate a 'completion.getSuggestions' response.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionGenerator {
  /**
   * The contributors to be used to generate the completion suggestions.
   */
  final List<CompletionContributor> contributors;

  /**
   * Initialize a newly created completion generator.
   */
  CompletionGenerator(this.contributors);

  /**
   * Create a 'completion.getSuggestions' response for the file with the given
   * [path]. If any of the contributors throws an exception, also create a
   * non-fatal 'plugin.error' notification.
   */
  Future<GeneratorResult> generateCompletionResponse(
      CompletionRequest request) async {
    List<Notification> notifications = <Notification>[];
    CompletionCollectorImpl collector = new CompletionCollectorImpl();
    try {
      for (CompletionContributor contributor in contributors) {
        request.checkAborted();
        try {
          await contributor.computeSuggestions(request, collector);
        } catch (exception, stackTrace) {
          notifications.add(new PluginErrorParams(
                  false, exception.toString(), stackTrace.toString())
              .toNotification());
        }
      }
    } on AbortCompletion {
      return new GeneratorResult(null, notifications);
    }
    collector.offset ??= request.offset;
    collector.length ??= 0;

    CompletionGetSuggestionsResult result = new CompletionGetSuggestionsResult(
        collector.offset, collector.length, collector.suggestions);
    return new GeneratorResult(result, notifications);
  }
}

/**
 * The information about a requested list of completions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CompletionRequest {
  /**
   * Return the offset within the source at which the completion is being
   * requested.
   */
  int get offset;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;

  /**
   * The analysis result for the file in which the completion is being
   * requested.
   */
  ResolveResult get result;

  /**
   * Throw an [AbortCompletion] if the completion request has been aborted.
   */
  void checkAborted();
}
