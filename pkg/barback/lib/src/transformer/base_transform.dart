// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.base_transform;

import 'dart:async';

import '../asset/asset_id.dart';
import '../graph/transform_node.dart';
import '../log.dart';
import 'transform_logger.dart';

/// The base class for the ephemeral transform objects that are passed to
/// transformers.
///
/// This class provides the transformers with inputs, but its up to the
/// subclasses to provide a means of emitting outputs.
abstract class BaseTransform {
  final TransformNode _node;

  /// The ids of primary inputs that should be consumed.
  ///
  /// This is exposed by [BaseTransformController].
  final _consumedPrimaries = new Set<AssetId>();

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
      if (asset == null) asset = _node.info.primaryId;
      var entry = new LogEntry(_node.info, asset, level, message, span);

      // The log controller can be closed while log entries are still coming in
      // if the transformer is removed during [apply].
      if (!_onLogController.isClosed) _onLogController.add(entry);
    });
  }

  /// Consume a primary input so that it doesn't get processed by future
  /// phases or emitted once processing has finished.
  ///
  /// Normally each primary input will automatically be forwarded unless the
  /// transformer overwrites it by emitting an input with the same id. This
  /// allows the transformer to tell barback not to forward a primary input
  /// even if it's not overwritten.
  void consumePrimary(AssetId id) {
    // TODO(nweiz): throw an error if an id is consumed that wasn't listed as a
    // primary input.
    _consumedPrimaries.add(id);
  }
}

/// The base class for controllers of subclasses of [BaseTransform].
///
/// Controllers are used so that [TransformNode]s can get values from a
/// [BaseTransform] without exposing getters in the public API.
abstract class BaseTransformController {
  /// The [BaseTransform] controlled by this controller.
  final BaseTransform transform;

  /// The ids of primary inputs that should be consumed.
  Set<AssetId> get consumedPrimaries => transform._consumedPrimaries;

  /// Whether the transform logged an error.
  bool get loggedError => transform._loggedError;

  /// The stream of log entries emitted by the transformer during a run.
  Stream<LogEntry> get onLog => transform._onLogController.stream;

  /// Whether the transform's input or id stream has been closed.
  ///
  /// See also [done].
  bool get isDone;

  BaseTransformController(this.transform);

  /// Mark this transform as finished emitting new inputs or input ids.
  ///
  /// This is distinct from [cancel] in that it *doesn't* indicate that the
  /// transform is finished being used entirely. The transformer may still log
  /// messages and load secondary inputs. This just indicates that all the
  /// primary inputs are accounted for.
  void done();

  /// Mark this transform as canceled.
  ///
  /// This will close any streams and release any resources that were allocated
  /// for the duration of the transformation. Unlike [done], this indicates that
  /// the transformation is no longer relevant; either it has returned, or
  /// something external has preemptively invalidated its results.
  void cancel() {
    done();
    transform._onLogController.close();
  }
}
