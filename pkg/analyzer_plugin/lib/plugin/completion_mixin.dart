// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';

/// A mixin that can be used when creating a subclass of [ServerPlugin] to
/// provide most of the implementation for handling code completion requests.
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin].
mixin CompletionMixin implements ServerPlugin {
  /// Return a list containing the completion contributors that should be used to
  /// create completion suggestions for the file with the given [path].
  List<CompletionContributor> getCompletionContributors(String path);

  /// Return the completion request that should be passes to the contributors
  /// returned from [getCompletionContributors].
  ///
  /// Throw a [RequestFailure] if the request could not be created.
  Future<CompletionRequest> getCompletionRequest(
      CompletionGetSuggestionsParams parameters);

  @override
  Future<CompletionGetSuggestionsResult> handleCompletionGetSuggestions(
      CompletionGetSuggestionsParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var request = await getCompletionRequest(parameters);
    var generator = CompletionGenerator(getCompletionContributors(path));
    var result = await generator.generateCompletionResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}

/// A mixin that can be used when creating a subclass of [ServerPlugin] and
/// mixing in [CompletionMixin]. This implements the creation of the completion
/// request based on the assumption that the driver being created is an
/// [AnalysisDriver].
///
/// Clients may not extend or implement this class, but are allowed to use it as
/// a mix-in when creating a subclass of [ServerPlugin] that also uses
/// [CompletionMixin] as a mix-in.
abstract class DartCompletionMixin implements CompletionMixin {
  @override
  Future<CompletionRequest> getCompletionRequest(
      CompletionGetSuggestionsParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var result = await getResolvedUnitResult(parameters.file);
    return DartCompletionRequestImpl(
        resourceProvider, parameters.offset, result);
  }
}
