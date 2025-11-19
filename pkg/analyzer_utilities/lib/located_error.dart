// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

/// An error with an associated source span.
class LocatedError {
  final SourceSpan span;
  final String message;

  LocatedError(this.message, {required this.span});

  @override
  String toString() => '${span.location}: $message';

  /// Executes [callback], converting any exceptions it generates to a
  /// [LocatedError] that points to [node].
  static T wrap<T>(T Function() callback, {required SourceSpan span}) {
    try {
      return callback();
    } catch (error, stackTrace) {
      if (error is! LocatedError) {
        Error.throwWithStackTrace(
          LocatedError(error.toString(), span: span),
          stackTrace,
        );
      } else {
        rethrow;
      }
    }
  }
}

extension SourceSpanLocation on SourceSpan {
  /// A string suitable for identifying this span in the source YAML file.
  String get location {
    var path = start.sourceUrl?.toFilePath() ?? '<unknown>';
    // Convert line/column to 1-based because that's what most editors expect
    var line = start.line + 1;
    var column = start.column + 1;
    return '$path:$line:$column';
  }
}
