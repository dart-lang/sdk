// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.transform;

import 'dart:async';
import 'dart:convert';

import '../asset/asset.dart';
import '../asset/asset_id.dart';
import '../errors.dart';
import 'aggregate_transform.dart';
import 'transform_logger.dart';

/// Creates a new [Transform] wrapping an [AggregateTransform].
///
/// Although barback internally works in terms of [AggregateTransformer]s, most
/// transformers only work on individual primary inputs in isolation. We want to
/// allow those transformers to implement the more user-friendly [Transformer]
/// interface which takes the more user-friendly [Transform] object. This method
/// wraps the more general [AggregateTransform] to return a [Transform] instead.
Future<Transform> newTransform(AggregateTransform aggregate) {
  // A wrapped [Transformer] will assign each primary input a unique transform
  // key, so we can safely get the first asset emitted. We don't want to wait
  // for the stream to close, since that requires barback to prove that no more
  // new assets will be generated.
  return aggregate.primaryInputs.first.then((primaryInput) =>
      new Transform._(aggregate, primaryInput));
}

/// While a [Transformer] represents a *kind* of transformation, this defines
/// one specific usage of it on a set of files.
///
/// This ephemeral object exists only during an actual transform application to
/// facilitate communication between the [Transformer] and the code hosting
/// the transformation. It lets the [Transformer] access inputs and generate
/// outputs.
class Transform {
  /// The underlying aggregate transform.
  final AggregateTransform _aggregate;

  /// Gets the primary input asset.
  ///
  /// While a transformation can use multiple input assets, one must be a
  /// special "primary" asset. This will be the "entrypoint" or "main" input
  /// file for a transformation.
  ///
  /// For example, with a dart2js transform, the primary input would be the
  /// entrypoint Dart file. All of the other Dart files that that imports
  /// would be secondary inputs.
  final Asset primaryInput;

  /// A logger so that the [Transformer] can report build details.
  TransformLogger get logger => _aggregate.logger;

  Transform._(this._aggregate, this.primaryInput);

  /// Gets the asset for an input [id].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) => _aggregate.getInput(id);

  /// A convenience method to the contents of the input with [id] as a string.
  ///
  /// This is equivalent to calling [getInput] followed by [Asset.readAsString].
  ///
  /// If the asset was created from a [String] the original string is always
  /// returned and [encoding] is ignored. Otherwise, the binary data of the
  /// asset is decoded using [encoding], which defaults to [UTF8].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<String> readInputAsString(AssetId id, {Encoding encoding}) =>
      _aggregate.readInputAsString(id, encoding: encoding);

  /// A convenience method to the contents of the input with [id].
  ///
  /// This is equivalent to calling [getInput] followed by [Asset.read].
  ///
  /// If the asset was created from a [String], this returns its UTF-8 encoding.
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Stream<List<int>> readInput(AssetId id) => _aggregate.readInput(id);

  /// A convenience method to return whether or not an asset exists.
  ///
  /// This is equivalent to calling [getInput] and catching an
  /// [AssetNotFoundException].
  Future<bool> hasInput(AssetId id) => _aggregate.hasInput(id);

  /// Stores [output] as the output created by this transformation.
  ///
  /// A transformation can output as many assets as it wants.
  void addOutput(Asset output) => _aggregate.addOutput(output);

  /// Consume the primary input so that it doesn't get processed by future
  /// phases or emitted once processing has finished.
  ///
  /// Normally the primary input will automatically be forwarded unless the
  /// transformer overwrites it by emitting an input with the same id. This
  /// allows the transformer to tell barback not to forward the primary input
  /// even if it's not overwritten.
  void consumePrimary() => _aggregate.consumePrimary(primaryInput.id);
}
