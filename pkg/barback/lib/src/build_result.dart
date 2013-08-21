// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.build_result;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'errors.dart';
import 'utils.dart';

/// An event indicating that the cascade has finished building all assets.
///
/// A build can end either in success or failure. If there were no errors during
/// the build, it's considered to be a success; any errors render it a failure,
/// although individual assets may still have built successfully.
class BuildResult {
  /// All errors that occurred during the build.
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
