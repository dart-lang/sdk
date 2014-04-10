// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform;

import 'dart:async';
import 'dart:convert';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_set.dart';
import 'base_transform.dart';
import 'errors.dart';
import 'transform_node.dart';
import 'utils.dart';

/// While a [Transformer] represents a *kind* of transformation, this defines
/// one specific usage of it on a set of files.
///
/// This ephemeral object exists only during an actual transform application to
/// facilitate communication between the [Transformer] and the code hosting
/// the transformation. It lets the [Transformer] access inputs and generate
/// outputs.
class Transform extends BaseTransform {
  final TransformNode _node;

  final _outputs = new AssetSet();

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
    if (!_node.primary.state.isAvailable) {
      throw new AssetNotFoundException(_node.primary.id);
    }

    return _node.primary.asset;
  }

  Transform._(TransformNode node)
    : _node = node,
      super(node);

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

  /// Stores [output] as the output created by this transformation.
  ///
  /// A transformation can output as many assets as it wants.
  void addOutput(Asset output) {
    // TODO(rnystrom): This should immediately throw if an output with that ID
    // has already been created by this transformer.
    _outputs.add(output);
  }
}

/// The controller for [Transform].
class TransformController extends BaseTransformController {
  Transform get transform => super.transform;

  /// The set of assets that the transformer has emitted.
  AssetSet get outputs => transform._outputs;

  TransformController(TransformNode node)
      : super(new Transform._(node));
}
