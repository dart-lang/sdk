// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.transformer_classifier;

import 'dart:async';

import '../asset/asset_forwarder.dart';
import '../asset/asset_node.dart';
import '../errors.dart';
import '../log.dart';
import '../transformer/aggregate_transformer.dart';
import '../transformer/wrapping_aggregate_transformer.dart';
import '../utils.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase.dart';
import 'transform_node.dart';

/// A class for classifying the primary inputs for a transformer according to
/// its [AggregateTransformer.classifyPrimary] method.
///
/// This is also used for non-aggregate transformers; they're modeled as
/// aggregate transformers that return the primary path if `isPrimary` is true
/// and `null` if `isPrimary` is `null`.
class TransformerClassifier {
  /// The containing [Phase].
  final Phase phase;

  /// The [AggregateTransformer] used to classify the inputs.
  final AggregateTransformer transformer;

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

  /// A broadcast stream that emits an event whenever [this] has finished
  /// classifying all available inputs.
  Stream get onDoneClassifying => _onDoneClassifyingController.stream;
  final _onDoneClassifyingController =
      new StreamController.broadcast(sync: true);

  /// The number of currently-active calls to [transformer.classifyPrimary].
  ///
  /// This is used to determine whether [this] is dirty.
  var _activeClassifications = 0;

  /// Whether this is currently classifying any inputs.
  bool get isClassifying => _activeClassifications > 0;

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    if (isClassifying) return NodeStatus.RUNNING;
    return NodeStatus.dirtiest(
        _transforms.values.map((transform) => transform.status));
  }

  TransformerClassifier(this.phase, transformer, this._location)
      : transformer = transformer is AggregateTransformer ?
            transformer : new WrappingAggregateTransformer(transformer);

  /// Adds a new asset as an input for this transformer.
  void addInput(AssetNode input) {
    _activeClassifications++;
    syncFuture(() => transformer.classifyPrimary(input.id)).catchError(
        (error, stackTrace) {
      if (input.state.isRemoved) return null;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      var info = new TransformInfo(transformer, input.id);
      if (error is! AssetNotFoundException) {
        error = new TransformerException(info, error, stackTrace);
      } else {
        error = new MissingInputException(info, error.id);
      }
      phase.cascade.reportError(error);

      return null;
    }).then((key) {
      if (input.state.isRemoved) return;
      if (key == null) {
        var forwarder = new AssetForwarder(input);
        _passThroughForwarders.add(forwarder);
        forwarder.node.whenRemoved(
            () => _passThroughForwarders.remove(forwarder));
        _streams.onAssetController.add(forwarder.node);
      } else if (_transforms.containsKey(key)) {
        _transforms[key].addPrimary(input);
      } else {
        var transform = new TransformNode(this, transformer, key, _location);
        _transforms[key] = transform;

        transform.onStatusChange.listen(
            (_) => _streams.changeStatus(status),
            onDone: () {
          _transforms.remove(transform.key);
          if (!_streams.isClosed) _streams.changeStatus(status);
        });

        _streams.onAssetPool.add(transform.onAsset);
        _streams.onLogPool.add(transform.onLog);
        transform.addPrimary(input);
      }
    }).whenComplete(() {
      _activeClassifications--;
      if (_streams.isClosed) return;
      if (!isClassifying) _onDoneClassifyingController.add(null);
      _streams.changeStatus(status);
    });
  }

  /// Removes this transformer.
  ///
  /// This marks all outputs of the transformer as removed.
  void remove() {
    _streams.close();
    _onDoneClassifyingController.close();
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
