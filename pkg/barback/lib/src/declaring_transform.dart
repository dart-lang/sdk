// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.declaring_transform;

import 'asset_id.dart';
import 'base_transform.dart';
import 'transform_logger.dart';
import 'transform_node.dart';

/// A transform for [DeclaringTransform]ers that allows them to declare the ids
/// of the outputs they'll generate without generating the concrete bodies of
/// those outputs.
class DeclaringTransform extends BaseTransform {
  final Set<AssetId> _outputIds;

  DeclaringTransform(TransformNode node, this._outputIds,
      LogFunction logFunction)
    : super(node, logFunction);

  /// Stores [id] as the id of an output that will be created by this
  /// transformation when it's run.
  ///
  /// A transformation can declare as many assets as it wants. If
  /// [DeclaringTransformer.declareOutputs] declareds a given asset id for a
  /// given input, [Transformer.apply] should emit the corresponding asset as
  /// well.
  void declareOutput(AssetId id) {
    // TODO(nweiz): This should immediately throw if an output with that ID
    // has already been declared by this transformer.
    _outputIds.add(id);
  }
}
