// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * A mixin that can be used when creating a subclass of [ServerPlugin] to
 * provide most of the implementation for handling code completion requests.
 *
 * Clients may not extend or implement this class, but are allowed to use it as
 * a mix-in when creating a subclass of [ServerPlugin].
 */
abstract class CompletionMixin implements ServerPlugin {
  /**
   * Return a list containing the completion contributors that should be used to
   * create completion suggestions when used in the context of the given
   * analysis [driver].
   */
  List<CompletionContributor> getCompletionContributors(
      covariant AnalysisDriverGeneric driver);

  /**
   * Return the result of using the given analysis [driver] to produce a fully
   * resolved AST for the file with the given [path].
   */
  Future<ResolveResult> getResolveResultForCompletion(
      covariant AnalysisDriverGeneric driver, String path);

  @override
  Future<CompletionGetSuggestionsResult> handleCompletionGetSuggestions(
      CompletionGetSuggestionsParams parameters) async {
    String path = parameters.file;
    ContextRoot contextRoot = contextRootContaining(path);
    if (contextRoot == null) {
      // Return an error from the request.
      throw new RequestFailure(
          RequestErrorFactory.pluginError('Failed to analyze $path', null));
    }
    AnalysisDriverGeneric driver = driverMap[contextRoot];
    ResolveResult analysisResult =
        await getResolveResultForCompletion(driver, path);
    CompletionRequestImpl request = new CompletionRequestImpl(
        resourceProvider, analysisResult, parameters.offset);
    CompletionGenerator generator =
        new CompletionGenerator(getCompletionContributors(driver));
    GeneratorResult result =
        await generator.generateCompletionResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}
