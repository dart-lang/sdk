// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.transform_logger;

import 'package:source_maps/span.dart';
import 'package:source_span/source_span.dart';

import '../asset/asset_id.dart';
import '../log.dart';
import '../span_wrapper.dart';

typedef void LogFunction(AssetId asset, LogLevel level, String message,
                         Span span);

/// Object used to report warnings and errors encountered while running a
/// transformer.
class TransformLogger {
  final LogFunction _logFunction;

  TransformLogger(this._logFunction);

  /// Logs an informative message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer]. If
  /// present, [span] indicates the location in the input asset that caused the
  /// error. It may be a [SourceSpan] or a [Span], although the former is
  /// recommended.
  void info(String message, {AssetId asset, span}) {
    if (span != null && span is SourceSpan) span = new SpanWrapper(span, false);
    _logFunction(asset, LogLevel.INFO, message, span);
  }

  /// Logs a message that won't be displayed unless the user is running in
  /// verbose mode.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer]. If
  /// present, [span] indicates the location in the input asset that caused the
  /// error. It may be a [SourceSpan] or a [Span], although the former is
  /// recommended.
  void fine(String message, {AssetId asset, span}) {
    if (span != null && span is SourceSpan) span = new SpanWrapper(span, false);
    _logFunction(asset, LogLevel.FINE, message, span);
  }

  /// Logs a warning message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer]. If
  /// present, [span] indicates the location in the input asset that caused the
  /// error. It may be a [SourceSpan] or a [Span], although the former is
  /// recommended.
  void warning(String message, {AssetId asset, span}) {
    if (span != null && span is SourceSpan) span = new SpanWrapper(span, false);
    _logFunction(asset, LogLevel.WARNING, message, span);
  }

  /// Logs an error message.
  ///
  /// If [asset] is provided, the log entry is associated with that asset.
  /// Otherwise it's associated with the primary input of [transformer]. If
  /// present, [span] indicates the location in the input asset that caused the
  /// error. It may be a [SourceSpan] or a [Span], although the former is
  /// recommended.
  ///
  /// Logging any errors will cause Barback to consider the transformation to
  /// have failed, much like throwing an exception. This means that neither the
  /// primary input nor any outputs emitted by the transformer will be passed on
  /// to the following phase, and the build will be reported as having failed.
  ///
  /// Unlike throwing an exception, this doesn't cause a transformer to stop
  /// running. This makes it useful in cases where a single input may have
  /// multiple errors that the user wants to know about.
  void error(String message, {AssetId asset, span}) {
    if (span != null && span is SourceSpan) span = new SpanWrapper(span, false);
    _logFunction(asset, LogLevel.ERROR, message, span);
  }
}
