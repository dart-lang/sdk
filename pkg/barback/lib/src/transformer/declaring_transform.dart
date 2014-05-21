// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.declaring_transform;

import 'dart:async';

import '../asset/asset_id.dart';
import 'declaring_aggregate_transform.dart';
import 'transform_logger.dart';

/// Creates a new [DeclaringTransform] wrapping an
/// [AggregateDeclaringTransform].
///
/// Although barback internally works in terms of
/// [DeclaringAggregateTransformer]s, most transformers only work on individual
/// primary inputs in isolation. We want to allow those transformers to
/// implement the more user-friendly [DeclaringTransformer] interface which
/// takes the more user-friendly [DeclaringTransform] object. This method wraps
/// the more general [DeclaringAggregateTransform] to return a
/// [DeclaringTransform] instead.
Future<DeclaringTransform> newDeclaringTransform(
    DeclaringAggregateTransform aggregate) {
  // A wrapped [Transformer] will assign each primary input a unique transform
  // key, so we can safely get the first asset emitted. We don't want to wait
  // for the stream to close, since that requires barback to prove that no more
  // new assets will be generated.
  return aggregate.primaryIds.first.then((primaryId) => 
      new DeclaringTransform._(aggregate, primaryId));
}

/// A transform for [DeclaringTransformer]s that allows them to declare the ids
/// of the outputs they'll generate without generating the concrete bodies of
/// those outputs.
class DeclaringTransform {
  /// The underlying aggregate transform.
  final DeclaringAggregateTransform _aggregate;

  final AssetId primaryId;

  /// A logger so that the [Transformer] can report build details.
  TransformLogger get logger => _aggregate.logger;

  DeclaringTransform._(this._aggregate, this.primaryId);

  /// Stores [id] as the id of an output that will be created by this
  /// transformation when it's run.
  ///
  /// A transformation can declare as many assets as it wants. If
  /// [DeclaringTransformer.declareOutputs] declareds a given asset id for a
  /// given input, [Transformer.apply] should emit the corresponding asset as
  /// well.
  void declareOutput(AssetId id) => _aggregate.declareOutput(id);

  /// Consume the primary input so that it doesn't get processed by future
  /// phases or emitted once processing has finished.
  ///
  /// Normally the primary input will automatically be forwarded unless the
  /// transformer overwrites it by emitting an input with the same id. This
  /// allows the transformer to tell barback not to forward the primary input
  /// even if it's not overwritten.
  void consumePrimary() => _aggregate.consumePrimary(primaryId);
}
