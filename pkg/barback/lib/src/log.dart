// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.log;

import 'package:source_maps/span.dart';

import 'asset_id.dart';
import 'errors.dart';

/// The severity of a logged message.
class LogLevel {
  static const INFO = const LogLevel("Info");
  static const FINE = const LogLevel("Fine");
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
  final AssetId assetId;

  final LogLevel level;
  final String message;

  /// The location that the message pertains to or null if not associated with
  /// a source [Span].
  final Span span;

  LogEntry(this.transform, this.assetId, this.level, this.message, this.span);
}
