// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.declaring_aggregate_transform;

import 'dart:async';

import '../asset/asset_id.dart';
import '../graph/transform_node.dart';
import '../utils.dart';
import 'base_transform.dart';

/// A transform for [DeclaringAggregateTransformer]s that allows them to declare
/// the ids of the outputs they'll generate without generating the concrete
/// bodies of those outputs.
class DeclaringAggregateTransform extends BaseTransform {
  /// The set of output ids declared by the transformer.
  final _outputIds = new Set<AssetId>();

  /// The transform key.
  ///
  /// This is the key returned by [AggregateTransformer.classifyPrimary] for all
  /// the assets in this transform.
  final String key;

  /// The package in which this transform is running.
  final String package;

  /// The stream of primary input ids that have been aggregated for this
  /// transform.
  ///
  /// This is exposed as a stream so that the transformer can start working
  /// before all its input ids are available. The stream is closed not just when
  /// all inputs are provided, but when barback is confident no more inputs will
  /// be forthcoming.
  ///
  /// A transformer may complete its `declareOutputs` method before this stream
  /// is closed. For example, it may know that each key will only have two
  /// inputs associated with it, and so use `transform.primaryIds.take(2)` to
  /// access only those inputs' ids.
  Stream<AssetId> get primaryIds => _primaryIds;
  Stream<AssetId> _primaryIds;

  /// The controller for [primaryIds].
  ///
  /// This is a broadcast controller so that the transform can keep
  /// [_emittedPrimaryIds] up to date.
  final _idController = new StreamController<AssetId>.broadcast();

  /// The set of all primary input ids that have been emitted by [primaryIds].
  final _emittedPrimaryIds = new Set<AssetId>();

  DeclaringAggregateTransform._(TransformNode node)
      : key = node.key,
        package = node.phase.cascade.package,
        super(node) {
    _idController.stream.listen(_emittedPrimaryIds.add);
    // [primaryIds] should be a non-broadcast stream.
    _primaryIds = broadcastToSingleSubscription(_idController.stream);
  }

  /// Stores [id] as the id of an output that will be created by this
  /// transformation when it's run.
  ///
  /// A transformation can declare as many assets as it wants. If
  /// [DeclaringTransformer.declareOutputs] declares a given asset id for a
  /// given input, [Transformer.apply] should emit the corresponding asset as
  /// well.
  void declareOutput(AssetId id) {
    // TODO(nweiz): This should immediately throw if an output with that ID
    // has already been declared by this transformer.
    _outputIds.add(id);
  }

  void consumePrimary(AssetId id) {
    if (!_emittedPrimaryIds.contains(id)) {
      throw new StateError(
          "$id can't be consumed because it's not a primary input.");
    }

    super.consumePrimary(id);
  }
}

/// The controller for [DeclaringAggregateTransform].
class DeclaringAggregateTransformController extends BaseTransformController {
  DeclaringAggregateTransform get transform => super.transform;

  /// The set of ids that the transformer declares it will emit.
  Set<AssetId> get outputIds => transform._outputIds;

  bool get isDone => transform._idController.isClosed;

  DeclaringAggregateTransformController(TransformNode node)
      : super(new DeclaringAggregateTransform._(node));

  /// Adds a primary input id to the [DeclaringAggregateTransform.primaryIds]
  /// stream.
  void addId(AssetId id) => transform._idController.add(id);

  void done() {
    transform._idController.close();
  }
}
