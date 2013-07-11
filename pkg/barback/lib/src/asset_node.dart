// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_node;

import 'dart:async';

import 'asset.dart';
import 'asset_graph.dart';
import 'asset_id.dart';
import 'phase.dart';
import 'transform_node.dart';

/// Describes an asset and its relationship to the build dependency graph.
///
/// Keeps a cache of the last asset that was built for this node (i.e. for this
/// node's ID and phase) and tracks which transforms depend on it.
class AssetNode {
  Asset asset;

  /// The [TransformNode]s that consume this node's asset as an input.
  final consumers = new Set<TransformNode>();

  AssetId get id => asset.id;

  AssetNode(this.asset);

  /// Updates this node's generated asset value and marks all transforms that
  /// use this as dirty.
  void updateAsset(Asset asset) {
    // Cannot update an asset to one with a different ID.
    assert(id == asset.id);

    this.asset = asset;
    consumers.forEach((consumer) => consumer.dirty());
  }
}
