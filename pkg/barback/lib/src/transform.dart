// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform;

import 'dart:async';
import 'dart:convert';

import 'package:source_maps/span.dart';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'log.dart';
import 'transform_logger.dart';
import 'transform_node.dart';
import 'utils.dart';

typedef void LogFunction(AssetId asset, LogLevel level, String message,
                         Span span);

/// Creates a [Transform] by forwarding to the private constructor.
///
/// Lets [TransformNode] create [Transforms] without giving a [Transform]
/// itself a public constructor, which would be visible to external users.
/// Unlike the [Transform] class, this function is not exported by barback.dart.
Transform createTransform(TransformNode node, AssetSet outputs,
                          LogFunction logFunction) =>
    new Transform._(node, outputs, logFunction);

/// While a [Transformer] represents a *kind* of transformation, this defines
/// one specific usage of it on a set of files.
///
/// This ephemeral object exists only during an actual transform application to
/// facilitate communication between the [Transformer] and the code hosting
/// the transformation. It lets the [Transformer] access inputs and generate
/// outputs.
class Transform {
  final TransformNode _node;
  final TransformLogger _logger;
  final AssetSet _outputs;

  /// A logger so that the [Transformer] can report build details.
  TransformLogger get logger => _logger;

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
  /// This method may fail at runtime if called asynchronously after the
  /// transform begins running. The primary input may become unavailable while
  /// this transformer is running due to asset changes earlier in the graph.
  /// You can ignore the error if this happens: the transformer will be re-run
  /// automatically for you.
  Asset get primaryInput {
    if (_node.primary.state != AssetState.AVAILABLE) {
      throw new AssetNotFoundException(_node.primary.id);
    }

    return _node.primary.asset;
  }

  Transform._(this._node, this._outputs, LogFunction logFunction)
    : _logger = new TransformLogger(logFunction);

  /// Gets the asset for an input [id].
  ///
  /// If an input with that ID cannot be found, throws an
  /// [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) => _node.getInput(id);

  /// A convenience method to the contents of the input with [id] as a string.
  ///
  /// This is equivalent to calling `getInput()` followed by `readAsString()`.
  ///
  /// If the asset was created from a [String] the original string is always
  /// returned and [encoding] is ignored. Otherwise, the binary data of the
  /// asset is decoded using [encoding], which defaults to [UTF8].
  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) => input.readAsString(encoding: encoding));
  }

  /// A convenience method to the contents of the input with [id].
  ///
  /// This is equivalent to calling `getInput()` followed by `read()`.
  ///
  /// If the asset was created from a [String], this returns its UTF-8 encoding.
  Stream<List<int>> readInput(AssetId id) =>
      futureStream(getInput(id).then((input) => input.read()));

  /// Stores [output] as the output created by this transformation.
  ///
  /// A transformation can output as many assets as it wants.
  void addOutput(Asset output) {
    // TODO(rnystrom): This should immediately throw if an output with that ID
    // has already been created by this transformer.
    _outputs.add(output);
  }
}
