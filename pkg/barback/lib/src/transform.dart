// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'transform_node.dart';
import 'utils.dart';

/// Creates a [Transform] by forwarding to the private constructor.
///
/// Lets [TransformNode] create [Transforms] without giving a [Transform]
/// itself a public constructor, which would be visible to external users.
/// Unlike the [Transform] class, this function is not exported by barback.dart.
Transform createTransform(TransformNode node, Set<AssetNode> inputs,
                          AssetSet outputs) =>
    new Transform._(node, inputs, outputs);

/// While a [Transformer] represents a *kind* of transformation, this defines
/// one specific usage of it on a set of files.
///
/// This ephemeral object exists only during an actual transform application to
/// facilitate communication between the [Transformer] and the code hosting
/// the transformation. It lets the [Transformer] access inputs and generate
/// outputs.
class Transform {
  final TransformNode _node;

  final Set<AssetNode> _inputs;
  final AssetSet _outputs;

  /// Gets the ID of the primary input for this transformation.
  ///
  /// While a transformation can use multiple input assets, one must be a
  /// special "primary" asset. This will be the "entrypoint" or "main" input
  /// file for a transformation.
  ///
  /// For example, with a dart2js transform, the primary input would be the
  /// entrypoint Dart file. All of the other Dart files that that imports
  /// would be secondary inputs.
  AssetId get primaryId => _node.primary.id;

  /// Gets the asset for the primary input.
  Future<Asset> get primaryInput => getInput(primaryId);

  Transform._(this._node, this._inputs, this._outputs);

  /// Gets the asset for for an input [id].
  ///
  /// If an input with that ID cannot be found, throws an
  /// [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) {
    return newFuture(() {
      var node = _node.phase.inputs[id];
      // TODO(rnystrom): Need to handle passthrough where an asset from a
      // previous phase can be found.

      // Throw if the input isn't found. This ensures the transformer's apply
      // is exited. We'll then catch this and report it through the proper
      // results stream.
      if (node == null) throw new MissingInputException(id);

      // If the asset node is found, wait until its contents are actually
      // available before we return them.
      return node.whenAvailable.then((asset) {
        _inputs.add(node);
        return asset;
      }).catchError((error) {
        if (error is! AssetNotFoundException || error.id != id) throw error;
        // If the node was removed before it could be loaded, treat it as though
        // it never existed and throw a MissingInputException.
        throw new MissingInputException(id);
      });
    });
  }

  /// Stores [output] as the output created by this transformation.
  ///
  /// A transformation can output as many assets as it wants.
  void addOutput(Asset output) {
    // TODO(rnystrom): This should immediately throw if an output with that ID
    // has already been created by this transformer.
    _outputs.add(output);
  }
}
