// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_logger;

import 'package:source_maps/span.dart';

import 'asset_id.dart';
import 'log.dart';
import 'transform.dart';

/// Object used to report warnings and errors encountered while running a
/// transformer.
class TransformLogger {
  final LogFunction _logFunction;

  TransformLogger(this._logFunction);

  /// Logs an informative message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer].
  /// If [span] is provided, indicates the location in the input asset that
  /// caused the message.
  void info(String message, {AssetId asset, Span span}) {
    _logFunction(asset, LogLevel.INFO, message, span);
  }

  /// Logs a warning message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer].
  /// If present, [span] indicates the location in the input asset that caused
  /// the warning.
  void warning(String message, {AssetId asset, Span span}) {
    _logFunction(asset, LogLevel.WARNING, message, span);
  }

  /// Logs an error message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer].
  /// If present, [span] indicates the location in the input asset that caused
  /// the error.
  // TODO(sigmund,nweiz): clarify when an error should be logged or thrown.
  void error(String message, {AssetId asset, Span span}) {
    _logFunction(asset, LogLevel.ERROR, message, span);
  }
}
