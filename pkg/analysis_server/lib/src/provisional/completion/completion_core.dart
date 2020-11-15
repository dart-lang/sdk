// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// [AbortCompletion] is thrown when the current completion request
/// should be aborted because either
/// the source changed since the request was made, or
/// a new completion request was received.
class AbortCompletion {}

/// An object used to produce completions at a specific location within a file.
///
/// Clients may implement this class when implementing plugins.
abstract class CompletionContributor {
  /// Return a [Future] that completes with a list of suggestions
  /// for the given completion [request]. This will
  /// throw [AbortCompletion] if the completion request has been aborted.
  Future<List<CompletionSuggestion>> computeSuggestions(
      CompletionRequest request);
}

/// The information about a requested list of completions.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CompletionRequest {
  /// Return the offset within the source at which the completion is being
  /// requested.
  int get offset;

  /// Return the resource provider associated with this request.
  ResourceProvider get resourceProvider;

  /// The analysis result for the file in which the completion is being
  /// requested.
  ResolvedUnitResult get result;

  /// Return the source in which the completion is being requested.
  Source get source;

  /// Return the content of the [source] in which the completion is being
  /// requested, or `null` if the content could not be accessed.
  String get sourceContents;

  /// Throw [AbortCompletion] if the completion request has been aborted.
  void checkAborted();
}
