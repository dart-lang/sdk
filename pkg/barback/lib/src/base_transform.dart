// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.base_transform;

import 'dart:async';
import 'dart:convert';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'errors.dart';
import 'log.dart';
import 'transform_logger.dart';
import 'transform_node.dart';
import 'utils.dart';

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

  /// Gets the primary input asset.
  ///
  /// While a transformation can use multiple input assets, one must be a
  /// special "primary" asset. This will be the "entrypoint" or "main" input
  /// file for a transformation.
  ///
  /// For example, with a dart2js transform, the primary input would be the
  /// entrypoint Dart file. All of the other Dart files that that imports
  /// would be secondary inputs.
  ///
  /// This method may fail at runtime with an [AssetNotFoundException] if called
  /// asynchronously after the transform begins running. The primary input may
  /// become unavailable while this transformer is running due to asset changes
  /// earlier in the graph. You can ignore the error if this happens: the
  /// transformer will be re-run automatically for you.
  Asset get primaryInput {
    if (_node.primary.state != AssetState.AVAILABLE) {
      throw new AssetNotFoundException(_node.primary.id);
    }

    return _node.primary.asset;
  }

  BaseTransform(this._node) {
    _logger = new TransformLogger((asset, level, message, span) {
      if (level == LogLevel.ERROR) _loggedError = true;

      // If the log isn't already associated with an asset, use the primary.
      if (asset == null) asset = _node.primary.id;
      var entry = new LogEntry(_node.info, asset, level, message, span);
      _onLogController.add(entry);
    });
  }

  /// Gets the asset for an input [id].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) => _node.getInput(id);

  /// A convenience method to the contents of the input with [id] as a string.
  ///
  /// This is equivalent to calling [getInput] followed by [Asset.readAsString].
  ///
  /// If the asset was created from a [String] the original string is always
  /// returned and [encoding] is ignored. Otherwise, the binary data of the
  /// asset is decoded using [encoding], which defaults to [UTF8].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) => input.readAsString(encoding: encoding));
  }

  /// A convenience method to the contents of the input with [id].
  ///
  /// This is equivalent to calling [getInput] followed by [Asset.read].
  ///
  /// If the asset was created from a [String], this returns its UTF-8 encoding.
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Stream<List<int>> readInput(AssetId id) =>
      futureStream(getInput(id).then((input) => input.read()));

  /// A convenience method to return whether or not an asset exists.
  ///
  /// This is equivalent to calling [getInput] and catching an
  /// [AssetNotFoundException].
  Future<bool> hasInput(AssetId id) {
    return getInput(id).then((_) => true).catchError((error) {
      if (error is AssetNotFoundException && error.id == id) return false;
      throw error;
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
