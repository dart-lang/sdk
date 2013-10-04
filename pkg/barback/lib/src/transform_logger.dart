// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_logger;

import 'package:source_maps/span.dart';

/// Object used to report warnings and errors encountered while running a
/// transformer.
class TransformLogger {

  bool _shouldPrint;

  TransformLogger(this._shouldPrint);

  /// Logs an informative message.
  ///
  /// If present, [span] indicates the location in the input asset that caused
  /// the message.
  void info(String message, [Span span]) {
    _printMessage('info', message, span);
  }

  /// Logs a warning message.
  ///
  /// If present, [span] indicates the location in the input asset that caused
  /// the warning.
  void warning(String message, [Span span]) {
    _printMessage('warning', message, span);
  }

  /// Logs an error message.
  ///
  /// If present, [span] indicates the location in the input asset that caused
  /// the error.
  // TODO(sigmund,nweiz): clarify when an error should be logged or thrown.
  void error(String message, [Span span]) {
    _printMessage('error', message, span);
  }

  // TODO(sigmund,rnystrom): do something better than printing.
  _printMessage(String prefix, String message, Span span) {
    if (!_shouldPrint) return;
    print(span == null ? '$prefix: $message'
        : '$prefix ${span.getLocationMessage(message)}');
  }
}
