// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.base_transform;

import 'dart:async';

import 'log.dart';
import 'transform_logger.dart';
import 'transform_node.dart';

/// The base class for the ephemeral transform objects that are passed to
/// transformers.
///
/// This class provides the transformers with inputs, but its up to the
/// subclasses to provide a means of emitting outputs.
abstract class BaseTransform {
  final TransformNode _node;

  /// Whether the primary input should be consumed.
  ///
  /// This is exposed via [BaseTransformController].
  bool _consumePrimary = false;

  /// Whether the transformer logged an error.
  ///
  /// This is exposed via [BaseTransformController].
  bool _loggedError = false;

  /// The controller for the stream of log entries emitted by the transformer.
  ///
  /// This is exposed via [BaseTransformController].
  ///
  /// This is synchronous because error logs can cause the transform to fail, so
  /// we need to ensure that their processing isn't delayed until after the
  /// transform or build has finished.
  final _onLogController = new StreamController<LogEntry>.broadcast(sync: true);

  /// A logger so that the [Transformer] can report build details.
  TransformLogger get logger => _logger;
  TransformLogger _logger;

  BaseTransform(this._node) {
    _logger = new TransformLogger((asset, level, message, span) {
      if (level == LogLevel.ERROR) _loggedError = true;

      // If the log isn't already associated with an asset, use the primary.
      if (asset == null) asset = _node.primary.id;
      var entry = new LogEntry(_node.info, asset, level, message, span);
      _onLogController.add(entry);
    });
  }

  /// Consume the primary input so that it doesn't get processed by future
  /// phases or emitted once processing has finished.
  ///
  /// Normally the primary input will automatically be forwarded unless the
  /// transformer overwrites it by emitting an input with the same id. This
  /// allows the transformer to tell barback not to forward the primary input
  /// even if it's not overwritten.
  void consumePrimary() {
    _consumePrimary = true;
  }
}

/// The base class for controllers of subclasses of [BaseTransform].
///
/// Controllers are used so that [TransformNode]s can get values from a
/// [BaseTransform] without exposing getters in the public API.
abstract class BaseTransformController {
  /// The [BaseTransform] controlled by this controller.
  final BaseTransform transform;

  /// Whether the primary input should be consumed.
  bool get consumePrimary => transform._consumePrimary;

  /// Whether the transform logged an error.
  bool get loggedError => transform._loggedError;

  /// The stream of log entries emitted by the transformer during a run.
  Stream<LogEntry> get onLog => transform._onLogController.stream;

  BaseTransformController(this.transform);

  /// Notifies the [BaseTransform] that the transformation has finished being
  /// applied.
  ///
  /// This will close any streams and release any resources that were allocated
  /// for the duration of the transformation.
  void close() {
    transform._onLogController.close();
  }
}
