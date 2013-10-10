// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.build_result;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'barback_logger.dart';
import 'errors.dart';
import 'utils.dart';

/// An event indicating that the cascade has finished building all assets.
///
/// A build can end either in success or failure. If there were no errors during
/// the build, it's considered to be a success; any errors render it a failure,
/// although individual assets may still have built successfully.
class BuildResult {
  // TODO(rnystrom): Revise how to track error results. Errors can come from
  // both logs and exceptions. Accumulating them is likely slow and a waste of
  // memory. If we do want to accumulate them, we should at least unify them
  // in a single collection (probably of log entries).
  /// All errors that were thrown during the build.
  final Set<BarbackException> errors;

  /// The number of error log entries that occurred during this build.
  final int _numErrorLogs;

  /// `true` if the build succeeded.
  bool get succeeded => errors.isEmpty && _numErrorLogs == 0;

  /// Gets the number of error exceptions and log entries.
  int get numErrors => errors.length + _numErrorLogs;

  BuildResult(Iterable<BarbackException> errors, this._numErrorLogs)
      : errors = flattenAggregateExceptions(errors).toSet();

  /// Creates a build result indicating a successful build.
  ///
  /// This equivalent to a build result with no errors.
  BuildResult.success()
      : this([], 0);

  String toString() {
    if (succeeded) return "success";

    return "errors:\n" + errors.map((error) {
      var stackTrace = getAttachedStackTrace(error);
      if (stackTrace != null) stackTrace = new Trace.from(stackTrace);

      var msg = new StringBuffer();
      msg.write(prefixLines(error.toString()));
      if (stackTrace != null) {
        msg.write("\n\n");
        msg.write("Stack trace:\n");
        msg.write(prefixLines(stackTrace.toString()));
      }
      return msg.toString();
    }).join("\n\n");
  }
}
