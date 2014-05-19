// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.aggregate_transformer;

import '../asset/asset_id.dart';
import 'aggregate_transform.dart';

/// An alternate interface for transformers that want to perform aggregate
/// transformations on multiple inputs without any individual one of them being
/// considered "primary".
///
/// This is useful for transformers like image spriting, where all the images in
/// a directory need to be combined into a single image. A normal [Transformer]
/// can't do this gracefully since when it's running on a single image, it has
/// no way of knowing what other images exist to request as secondary inputs.
///
/// Aggregate transformers work by classifying assets into different groups
/// based on their ids in [classifyPrimary]. Then [apply] is run once for each
/// group. For example, a spriting transformer might put each image asset into a
/// group identified by its directory name. All images in a given directory will
/// end up in the same group, and they'll all be passed to one [apply] call.
///
/// If possible, aggregate transformers should implement
/// [DeclaringAggregateTransformer] as well to help barback optimize the package
/// graph.
abstract class AggregateTransformer {
  /// Classifies an asset id by returning a key identifying which group the
  /// asset should be placed in.
  ///
  /// All assets for which [classifyPrimary] returns the same key are passed
  /// together to the same [apply] call.
  ///
  /// This may return [Future<String>] or, if it's entirely synchronous,
  /// [String]. Any string can be used to classify an asset. If possible,
  /// though, this should return a path-like string to aid in logging.
  ///
  /// A return value of `null` indicates that the transformer is not interested
  /// in an asset. Assets with a key of `null` will not be passed to any [apply]
  /// call; this is equivalent to [Transformer.isPrimary] returning `false`.
  classifyPrimary(AssetId id);

  /// Runs this transformer on a group of primary inputs specified by
  /// [transform].
  ///
  /// If this does asynchronous work, it should return a [Future] that completes
  /// once it's finished.
  ///
  /// This may complete before [AggregateTransform.primarInputs] is closed. For
  /// example, it may know that each key will only have two inputs associated
  /// with it, and so use `transform.primaryInputs.take(2)` to access only those
  /// inputs.
  apply(AggregateTransform transform);

  String toString() => runtimeType.toString().replaceAll("Transformer", "");
}
