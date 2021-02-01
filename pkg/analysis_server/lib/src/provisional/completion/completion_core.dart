// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';

/// [AbortCompletion] is thrown when the current completion request
/// should be aborted because either
/// the source changed since the request was made, or
/// a new completion request was received.
class AbortCompletion {}

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
