// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.declaring_aggregate_transformer;

import 'declaring_aggregate_transform.dart';

/// An interface for [Transformer]s that can cheaply figure out which assets
/// they'll emit without doing the work of actually creating those assets.
///
/// If a transformer implements this interface, that allows barback to perform
/// optimizations to make the asset graph work more smoothly.
abstract class DeclaringAggregateTransformer {
  /// Declare which assets would be emitted for the primary input ids specified
  /// by [transform].
  ///
  /// This works a little like [AggregateTransformer.apply], with two main
  /// differences. First, instead of having access to the primary inputs'
  /// contents, it only has access to their ids. Second, instead of emitting
  /// [Asset]s, it just emits [AssetId]s through [transform.addOutputId].
  ///
  /// If this does asynchronous work, it should return a [Future] that completes
  /// once it's finished.
  ///
  /// This may complete before [DeclaringAggregateTransform.primaryIds] stream
  /// is closed. For example, it may know that each key will only have two
  /// inputs associated with it, and so use `transform.primaryIds.take(2)` to
  /// access only those inputs' ids.
  declareOutputs(DeclaringAggregateTransform transform);
}
