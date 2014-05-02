// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer_classifier;

import 'dart:async';

import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'errors.dart';
import 'log.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase.dart';
import 'transform_node.dart';
import 'transformer.dart';
import 'utils.dart';

/// A class for classifying the primary inputs for a transformer according to
/// its `classifyPrimary` method.
///
/// This is used for non-aggregate transformers; they're modeled as aggregate
/// transformers that return the primary path if `isPrimary` is true and `null`
/// if `isPrimary` is `null`.
class TransformerClassifier {
  /// The containing [Phase].
  final Phase _phase;

  /// The [Transformer] to use to classify the inputs.
  final Transformer transformer;

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The individual transforms for each classiciation key.
  final _transforms = new Map<Object, TransformNode>();

  /// Forwarders used to pass through assets that aren't used by [transformer].
  final _passThroughForwarders = new Set<AssetForwarder>();

  /// The streams exposed by this classifier.
  final _streams = new NodeStreams();
  Stream get onStatusChange => _streams.onStatusChange;
  Stream<AssetNode> get onAsset => _streams.onAsset;
  Stream<LogEntry> get onLog => _streams.onLog;

  /// The number of currently-active calls to [transformer.isPrimary].
  ///
  /// This is used to determine whether [this] is dirty.
  var _activeIsPrimaries = 0;

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    if (_activeIsPrimaries > 0) return NodeStatus.RUNNING;
    return NodeStatus.dirtiest(
        _transforms.values.map((transform) => transform.status));
  }

  TransformerClassifier(this._phase, this.transformer, this._location);

  /// Adds a new asset as an input for this transformer.
  void addInput(AssetNode input) {
    _activeIsPrimaries++;
    syncFuture(() => transformer.isPrimary(input.id)).catchError(
        (error, stackTrace) {
      if (input.state.isRemoved) return false;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      var info = new TransformInfo(transformer, input.id);
      if (error is! AssetNotFoundException) {
        error = new TransformerException(info, error, stackTrace);
      } else {
        error = new MissingInputException(info, error.id);
      }
      _phase.cascade.reportError(error);

      return false;
    }).then((isPrimary) {
      if (input.state.isRemoved) return;
      if (!isPrimary) {
        var forwarder = new AssetForwarder(input);
        _passThroughForwarders.add(forwarder);
        forwarder.node.whenRemoved(
            () => _passThroughForwarders.remove(forwarder));
        _streams.onAssetController.add(forwarder.node);
      } else {
        var transform = new TransformNode(
            _phase, transformer, input, _location);
        _transforms[input.id.path] = transform;

        transform.onStatusChange.listen(
            (_) => _streams.changeStatus(status),
            onDone: () => _transforms.remove(input.id.path));

        _streams.onAssetPool.add(transform.onAsset);
        _streams.onLogPool.add(transform.onLog);
      }
    }).whenComplete(() {
      _activeIsPrimaries--;
      if (!_streams.isClosed) _streams.changeStatus(status);
    });
  }

  /// Removes this transformer.
  ///
  /// This marks all outputs of the transformer as removed.
  void remove() {
    _streams.close();
    for (var transform in _transforms.values.toList()) {
      transform.remove();
    }
    for (var forwarder in _passThroughForwarders.toList()) {
      forwarder.close();
    }
  }

  /// Force all deferred transforms to begin producing concrete assets.
  void forceAllTransforms() {
    for (var transform in _transforms.values) {
      transform.force();
    }
  }

  String toString() => "classifier in $_location for $transformer";
}
