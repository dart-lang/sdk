// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.build_result;

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

  /// `true` if the build succeeded.
  bool get succeeded => errors.isEmpty;

  BuildResult(Iterable<BarbackException> errors)
      : errors = flattenAggregateExceptions(errors).toSet();

  /// Creates a build result indicating a successful build.
  ///
  /// This equivalent to a build result with no errors.
  BuildResult.success()
      : this([]);

  /// Creates a single [BuildResult] that contains all of the errors of
  /// [results].
  factory BuildResult.aggregate(Iterable<BuildResult> results) {
    var errors = unionAll(results.map((result) => result.errors));
    return new BuildResult(errors);
  }

  String toString() {
    if (succeeded) return "success";

    return "errors:\n" + errors.map((error) {
      var stackTrace = null;
      if (error is TransformerException || error is AssetLoadException) {
        stackTrace = error.stackTrace.terse;
      }

      var msg = new StringBuffer();
      msg.write(prefixLines(error.toString()));
      if (stackTrace != null) {
        msg.write("\n\n");
        msg.write("Stack chain:\n");
        msg.write(prefixLines(stackTrace.toString()));
      }
      return msg.toString();
    }).join("\n\n");
  }
}
