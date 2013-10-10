// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.barback_logger;

import 'package:source_maps/span.dart';

import 'asset_id.dart';
import 'errors.dart';

/// Object used to report warnings and errors encountered while running a
/// transformer.
class BarbackLogger {
  /// Logs [entry].
  void logEntry(LogEntry entry) {
    var buffer = new StringBuffer();
    buffer.write("[${entry.level} ${entry.transform}] ");

    var message = entry.message;
    if (entry.span == null) {
      buffer.write(entry.span.getLocationMessage(entry.message));
    } else {
      buffer.write(message);
    }

    print(buffer);
  }
}

/// The severity of a logged message.
class LogLevel {
  static const INFO = const LogLevel("Info");
  static const WARNING = const LogLevel("Warning");
  static const ERROR = const LogLevel("Error");

  final String name;
  const LogLevel(this.name);

  String toString() => name;
}

/// One message logged during a transform.
class LogEntry {
  /// The transform that logged the message.
  final TransformInfo transform;

  /// The asset that the message is associated with.
  final AssetId asset;

  final LogLevel level;
  final String message;

  /// The location that the message pertains to or null if not associated with
  /// a source [Span].
  final Span span;

  LogEntry(this.transform, this.asset, this.level, this.message, this.span);
}
